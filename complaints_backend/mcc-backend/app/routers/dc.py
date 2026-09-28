"""Module D: District Controller (8 APIs)."""
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import OFFICIAL_ROLES, RequestMeta, request_meta, require_roles
from app.core.errors import invalid_state, not_found, validation_error
from app.core.security import new_uuid
from app.core.timeutil import iso, utcnow
from app.db.session import get_db, queue_event
from app.models import Assignment, Complaint, Constituency, FlyingSquad, User, ViolationType
from app.services import geo
from app.services.access import assert_can_view, get_complaint, scope_complaints
from app.services.notify import notify_users, user_ids_for
from app.services.serializers import complaint_detail, paginate, summaries
from app.services.state_machine import active_assignment, ensure_status, transition

router = APIRouter(tags=["D. District Controller"])
dc_only = require_roles("DC")

QUEUE_GROUPS = {
    "unassigned": ["RECEIVED"],
    "in_field": ["ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED", "REPORT_RETURNED"],
    "with_ro": ["REPORT_SUBMITTED"],
    "escalated": ["ESCALATED"],
    "open": ["RECEIVED", "ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED", "REPORT_SUBMITTED", "REPORT_RETURNED",
             "ESCALATED"],
}


class AssignIn(BaseModel):
    squad_id: int
    note: str | None = Field(default=None, max_length=500)


class ReassignIn(AssignIn):
    reason: str = Field(min_length=3, max_length=500)


class DuplicateIn(BaseModel):
    original_complaint: str = Field(description="UUID or complaint number of the original complaint")
    remarks: str | None = Field(default=None, max_length=500)


class DropIn(BaseModel):
    reason_code: Literal["NOT_MCC_VIOLATION", "FAKE_EVIDENCE", "OUTSIDE_JURISDICTION", "INSUFFICIENT_DETAILS"]
    remarks: str = Field(min_length=5, max_length=500)


def _dc_complaint(db: Session, user: User, ident: str) -> Complaint:
    c = get_complaint(db, ident, for_update=True)
    assert_can_view(db, user, c)
    return c


def _load_squad(db: Session, user: User, squad_id: int) -> FlyingSquad:
    s = db.scalar(select(FlyingSquad).where(FlyingSquad.id == squad_id).with_for_update())
    if s is None or s.district_id != user.district_id or not s.is_active:
        raise not_found("Flying squad")
    if s.status != "AVAILABLE":
        raise invalid_state(f"Squad {s.code} is {s.status}", squad_status=s.status)
    return s


def _assign(db: Session, dc: User, c: Complaint, squad: FlyingSquad, note: str | None, meta: RequestMeta,
            reason: str | None = None) -> Assignment:
    dist_km = eta = None
    for row in geo.nearby_squads(db, c, limit=50, only_available=False):
        if row["squad"].id == squad.id:
            dist_km, eta = row["distance_km"], row["eta_min"]
    a = Assignment(uuid=new_uuid(), complaint_id=c.id, squad_id=squad.id, assigned_by=dc.id, note=note,
                   distance_km=dist_km, eta_min=eta, reassign_reason=reason)
    db.add(a)
    squad.status = "BUSY"
    db.flush()
    transition(db, c, "ASSIGNED", dc, meta, remarks=reason or note,
               audit_payload={"squad": squad.code, "reassign": bool(reason)})
    notify_users(db, user_ids_for(db, "FS", squad_id=squad.id), "ASSIGNMENT_NEW",
                 f"New complaint {c.complaint_no}",
                 f"{c.violation_type.name_en} at {c.address_text or 'the marked location'}. Accept within "
                 f"{settings.ACCEPT_WINDOW_MIN} min.", complaint=c,
                 data={"assignment_id": a.uuid, "latitude": c.latitude, "longitude": c.longitude})
    return a


@router.get("/dc/complaints", summary="D1 Live queue for my district, sorted by SLA left")
def dc_queue(status: str | None = Query(None, description="Comma list of statuses, or a group: "
                                                           "unassigned, in_field, with_ro, escalated, open"),
             ac: str | None = Query(None, description="AC code"),
             violation_type: str | None = None,
             sla_breached: bool | None = None,
             q: str | None = Query(None, description="Search complaint no. or address"),
             page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
             user: User = Depends(dc_only), db: Session = Depends(get_db)):
    query = scope_complaints(select(Complaint), user)
    statuses = QUEUE_GROUPS.get(status or "open") or [s.strip().upper() for s in status.split(",") if s.strip()]
    query = query.where(Complaint.status.in_(statuses))
    if ac:
        query = query.join(Constituency, Constituency.id == Complaint.ac_id).where(Constituency.code == ac)
    if violation_type:
        query = query.join(ViolationType, ViolationType.id == Complaint.violation_type_id) \
                     .where(ViolationType.code == violation_type)
    if sla_breached is not None:
        query = query.where(Complaint.is_sla_breached.is_(sla_breached))
    if q:
        query = query.where(or_(Complaint.complaint_no.like(f"%{q}%"), Complaint.address_text.like(f"%{q}%")))
    query = query.order_by(Complaint.stage_deadline.is_(None), Complaint.stage_deadline, Complaint.submitted_at)
    page_data = paginate(db, query, page, page_size, lambda c: c)
    page_data["results"] = summaries(db, page_data["results"])
    return page_data


@router.get("/complaints/{complaint_id}", summary="D2 Full complaint detail (shared by officials, filtered by role)")
def complaint_detail_api(complaint_id: str, user: User = Depends(require_roles(*OFFICIAL_ROLES)),
                         db: Session = Depends(get_db)):
    c = get_complaint(db, complaint_id)
    assert_can_view(db, user, c)
    return complaint_detail(db, c, user)


@router.get("/dc/complaints/{complaint_id}/nearby-squads", summary="D3 Free squads ranked by distance and ETA")
def nearby(complaint_id: str, include_busy: bool = False, user: User = Depends(dc_only),
           db: Session = Depends(get_db)):
    c = get_complaint(db, complaint_id)
    assert_can_view(db, user, c)
    rows = geo.nearby_squads(db, c, limit=10, only_available=not include_busy)
    members = {}
    for uid_squad in db.scalars(select(User.squad_id).where(User.squad_id.in_([r["squad"].id for r in rows] or [-1]),
                                                           User.is_active.is_(True))):
        members[uid_squad] = members.get(uid_squad, 0) + 1
    return {"results": [{"squad_id": r["squad"].id, "code": r["squad"].code, "status": r["squad"].status,
                         "distance_km": r["distance_km"], "eta_min": r["eta_min"],
                         "members": members.get(r["squad"].id, 0), "vehicle_no": r["squad"].vehicle_no,
                         "last_location_at": r["squad"].last_location_at} for r in rows]}


@router.post("/dc/complaints/{complaint_id}/assign", summary="D4 Assign a flying squad")
def assign(complaint_id: str, body: AssignIn, user: User = Depends(dc_only), db: Session = Depends(get_db),
           meta: RequestMeta = Depends(request_meta)):
    c = _dc_complaint(db, user, complaint_id)
    ensure_status(c, "RECEIVED")
    squad = _load_squad(db, user, body.squad_id)
    a = _assign(db, user, c, squad, body.note, meta)
    db.commit()
    return {"status": c.status, "assignment_id": a.uuid, "squad": squad.code, "stage_deadline": c.stage_deadline}


@router.post("/dc/complaints/{complaint_id}/reassign", summary="D5 Move to another squad with a reason")
def reassign(complaint_id: str, body: ReassignIn, user: User = Depends(dc_only), db: Session = Depends(get_db),
             meta: RequestMeta = Depends(request_meta)):
    c = _dc_complaint(db, user, complaint_id)
    ensure_status(c, "ASSIGNED", "ACCEPTED", "EN_ROUTE")
    old = active_assignment(db, c.id)
    if old and old.squad_id == body.squad_id:
        raise validation_error("Complaint is already with this squad")
    squad = _load_squad(db, user, body.squad_id)
    if old:
        old.is_active, old.ended_reason, old.ended_at = False, "REASSIGNED", utcnow()
        old_squad = db.get(FlyingSquad, old.squad_id)
        if old_squad and old_squad.status == "BUSY":
            old_squad.status = "AVAILABLE"
        notify_users(db, user_ids_for(db, "FS", squad_id=old.squad_id), "ASSIGNMENT_WITHDRAWN",
                     f"{c.complaint_no} reassigned", "This complaint was moved to another squad.", complaint=c)
    a = _assign(db, user, c, squad, body.note, meta, reason=body.reason)
    db.commit()
    return {"status": c.status, "assignment_id": a.uuid, "squad": squad.code, "stage_deadline": c.stage_deadline}


@router.post("/dc/complaints/{complaint_id}/mark-duplicate", summary="D6 Link to the original complaint")
def mark_duplicate(complaint_id: str, body: DuplicateIn, user: User = Depends(dc_only),
                   db: Session = Depends(get_db), meta: RequestMeta = Depends(request_meta)):
    c = _dc_complaint(db, user, complaint_id)
    ensure_status(c, "RECEIVED")
    original = get_complaint(db, body.original_complaint)
    assert_can_view(db, user, original)
    if original.id == c.id or original.status in ("DRAFT", "WITHDRAWN", "DUPLICATE"):
        raise validation_error("Original complaint is not valid for linking")
    c.duplicate_of_id = original.id
    transition(db, c, "DUPLICATE", user, meta, remarks=body.remarks or f"Duplicate of {original.complaint_no}",
               audit_payload={"original": original.complaint_no})
    db.commit()
    return {"status": c.status, "duplicate_of": original.complaint_no}


@router.post("/dc/complaints/{complaint_id}/drop", summary="D7 Drop as invalid with a reason")
def drop(complaint_id: str, body: DropIn, user: User = Depends(dc_only), db: Session = Depends(get_db),
         meta: RequestMeta = Depends(request_meta)):
    c = _dc_complaint(db, user, complaint_id)
    ensure_status(c, "RECEIVED")
    c.dc_drop_reason, c.dc_remarks = body.reason_code, body.remarks
    transition(db, c, "DROPPED_AT_DC", user, meta, remarks=body.remarks, audit_payload={"reason": body.reason_code})
    db.commit()
    return {"status": c.status}


@router.get("/dc/squads", summary="D8 All squads in my district with live status and last location")
def dc_squads(status: Literal["AVAILABLE", "BUSY", "OFF_DUTY"] | None = None,
              user: User = Depends(require_roles("DC", "DEO")), db: Session = Depends(get_db)):
    q = select(FlyingSquad).where(FlyingSquad.district_id == user.district_id, FlyingSquad.is_active.is_(True))
    if status:
        q = q.where(FlyingSquad.status == status)
    squads = db.scalars(q.order_by(FlyingSquad.code)).all()
    active = {a.squad_id: a for a in db.scalars(select(Assignment).where(
        Assignment.squad_id.in_([s.id for s in squads] or [-1]), Assignment.is_active.is_(True),
        Assignment.complaint.has(Complaint.status.in_(["ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED",
                                                       "REPORT_RETURNED"]))))}
    out = []
    for s in squads:
        lat, lng = geo.squad_lat_lng(db, s.id)
        a = active.get(s.id)
        out.append({"id": s.id, "code": s.code, "status": s.status, "vehicle_no": s.vehicle_no,
                    "last_location": {"latitude": lat, "longitude": lng} if lat is not None else None,
                    "last_location_at": s.last_location_at,
                    "active_complaint": ({"complaint_no": a.complaint.complaint_no, "status": a.complaint.status}
                                         if a else None)})
    return {"results": out, "summary": {st: sum(1 for s in squads if s.status == st)
                                        for st in ("AVAILABLE", "BUSY", "OFF_DUTY")}}


__all__ = ["router", "queue_event", "iso"]
