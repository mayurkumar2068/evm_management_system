"""Module N: Notifications and realtime (4 APIs, incl. 1 WebSocket)."""
import asyncio
import contextlib
from typing import Literal

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketDisconnect
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import get_current_user, user_from_token
from app.core.errors import APIError, not_found
from app.core.timeutil import utcnow
from app.db.session import SessionLocal, get_db
from app.models import Notification, User, UserDevice
from app.services.realtime import Connection, broadcaster
from app.services.serializers import paginate

router = APIRouter(tags=["N. Notifications & realtime"])


class DeviceIn(BaseModel):
    platform: Literal["ANDROID", "IOS", "WEB"]
    fcm_token: str = Field(min_length=10, max_length=255)
    app_version: str | None = Field(default=None, max_length=20)


@router.post("/devices", status_code=201, summary="N1 Register an FCM push token for the logged-in user")
def register_device(body: DeviceIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    dev = db.scalar(select(UserDevice).where(UserDevice.fcm_token == body.fcm_token))
    if dev is None:
        dev = UserDevice(user_id=user.id, platform=body.platform, fcm_token=body.fcm_token)
        db.add(dev)
    dev.user_id, dev.platform, dev.app_version = user.id, body.platform, body.app_version
    dev.is_active, dev.last_seen_at = True, utcnow()
    db.commit()
    return {"id": dev.id, "platform": dev.platform, "is_active": dev.is_active}


@router.get("/notifications", summary="N2 My in-app notifications")
def list_notifications(unread_only: bool = False, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                       user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    q = select(Notification).where(Notification.user_id == user.id)
    if unread_only:
        q = q.where(Notification.read_at.is_(None))
    data = paginate(db, q.order_by(Notification.created_at.desc(), Notification.id.desc()), page, page_size,
                    lambda n: {"id": n.id, "type": n.type, "title": n.title, "body": n.body, "data": n.data,
                               "read": n.read_at is not None, "created_at": n.created_at})
    data["unread"] = db.query(Notification).filter(Notification.user_id == user.id,
                                                   Notification.read_at.is_(None)).count()
    return data


@router.post("/notifications/{notification_id}/read", summary="N3 Mark a notification as read")
def mark_read(notification_id: int, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    n = db.get(Notification, notification_id)
    if n is None or n.user_id != user.id:
        raise not_found("Notification")
    n.read_at = n.read_at or utcnow()
    db.commit()
    return {"id": n.id, "read": True}


@router.websocket("/ws/live")
async def live(ws: WebSocket, token: str = Query(...)):
    """N4 Live events for web dashboards. Connect with ?token=<access token>.

    Events: complaint.created, complaint.status_changed, sla.warning, sla.breached,
    squad.location, squad.status_changed, notification.created
    """
    db = SessionLocal()
    try:
        user = user_from_token(db, token)
        conn = Connection(ws=ws, user_id=user.id, role=user.role, district_id=user.district_id,
                          ac_id=user.ac_id, squad_id=user.squad_id)
    except APIError:
        await ws.close(code=4401)
        return
    finally:
        db.close()
    await ws.accept()
    broadcaster.attach_loop(asyncio.get_running_loop())
    broadcaster.add(conn)
    await ws.send_json({"event": "connected", "data": {"role": conn.role}})

    async def pump():
        while True:
            await ws.send_text(await conn.queue.get())

    sender = asyncio.create_task(pump())
    try:
        while True:
            msg = await ws.receive_text()
            if msg == "ping":
                await ws.send_text("pong")
    except WebSocketDisconnect:
        pass
    finally:
        broadcaster.remove(conn)
        sender.cancel()
        with contextlib.suppress(asyncio.CancelledError, Exception):
            await sender
