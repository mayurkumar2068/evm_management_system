"""In-app notifications + push.

Every notification is stored (API N2/N3). Push delivery goes through
`PushSender`. The default sender only logs; plug in Firebase Admin SDK
(FCM HTTP v1 with a service account) in `FcmPushSender.send` for production.
"""
import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import queue_event
from app.models import Complaint, Notification, User, UserDevice

log = logging.getLogger("notify")


class PushSender:
    enabled = False

    def send(self, tokens: list[str], title: str, body: str, data: dict) -> bool:
        log.info("push (disabled) to %d devices: %s", len(tokens), title)
        return False


class FcmPushSender(PushSender):
    enabled = True

    def send(self, tokens: list[str], title: str, body: str, data: dict) -> bool:  # pragma: no cover
        # TODO: firebase_admin.messaging.send_each_for_multicast(...)
        log.info("FCM send to %d devices: %s", len(tokens), title)
        return True


push_sender: PushSender = FcmPushSender() if settings.FCM_SERVER_KEY else PushSender()


def notify_users(db: Session, user_ids: list[int], ntype: str, title: str, body: str,
                 complaint: Complaint | None = None, data: dict | None = None) -> None:
    user_ids = sorted(set(user_ids))
    if not user_ids:
        return
    payload = dict(data or {})
    if complaint is not None:
        payload.setdefault("complaint_id", complaint.uuid)
        payload.setdefault("complaint_no", complaint.complaint_no)
    tokens_by_user: dict[int, list[str]] = {}
    for d in db.scalars(select(UserDevice).where(UserDevice.user_id.in_(user_ids), UserDevice.is_active.is_(True))):
        tokens_by_user.setdefault(d.user_id, []).append(d.fcm_token)
    for uid in user_ids:
        tokens = tokens_by_user.get(uid, [])
        status = "SKIPPED"
        if tokens and push_sender.enabled:
            status = "SENT" if push_sender.send(tokens, title, body, payload) else "FAILED"
        db.add(Notification(user_id=uid, complaint_id=complaint.id if complaint else None, type=ntype,
                            title=title[:150], body=body[:500], data=payload, push_status=status))
    queue_event(db, "notification.created", {"type": ntype, "title": title, **payload},
                {"user_ids": user_ids, "only_users": True})


def user_ids_for(db: Session, role: str, district_id: int | None = None, ac_id: int | None = None,
                 squad_id: int | None = None) -> list[int]:
    q = select(User.id).where(User.role == role, User.is_active.is_(True))
    if district_id is not None:
        q = q.where(User.district_id == district_id)
    if ac_id is not None:
        q = q.where(User.ac_id == ac_id)
    if squad_id is not None:
        q = q.where(User.squad_id == squad_id)
    return list(db.scalars(q))
