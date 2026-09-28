"""Module F: Flying Squad (8 APIs)."""
from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import RequestMeta, request_meta, require_roles
from app.core.errors import forbidden, geo_mismatch, invalid_state, not_found, validation_error
from app.core.timeutil import iso, as_utc, utcnow
from app.db.session import get_db, queue_event
from app.models import Assignment, Complaint, ComplaintMedia, FieldReport, FlyingSquad, SeizureItem, SquadLocationLog, User
from app.services import geo
from app.services.media import media_out, save_media
from app.services.notify import notify_users, user_ids_for
from app.services.serializers import paginate, vt_out
from app.services.state_machine import transition

router = APIRouter(prefix="/fs", tags=["F. Flying Squad"])
fs_only = require_roles("FS")

IN_PROGRESS = ("ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED", "REPORT_RETURNED")


class GeoIn(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    accuracy_m: int | None = Field(default=None, ge=0, le=5000)


class LocationPoint(GeoIn):
    at: datetime


class LocationIn(BaseModel):
    points: list[LocationPoint] = Field(min_length=1, max_length=100)


class SeizureItemIn(BaseModel):
    type: Literal["CASH", "LIQUOR", "GIFTS", "DRUGS", "PRECIOUS_METAL", "OTHER"]
    description: str | None = Field(default=None, max_length=255)
    quantity: float = Field(gt=0)
    unit: str = Field(max_length=20)
    value_inr: float | None = Field(default=None, ge=0)


class SeizureIn(BaseModel):
    made: bool = False
    items: list[SeizureItemIn] = []


class ReportIn(BaseModel):
    finding: Literal["VIOLATION_CONFIRMED", "NOTHING_FOUND", "NOT_MCC", "PARTIAL"]
    summary: str = Field(min_length=10, max_length=5000)
    party_or_candidate: str | None = Field(default=None, max_length=200)
    actions_taken: list[Literal["MATERIAL_REMOVED", "PANCHNAMA", "STATEMENT_RECORDED", "SEIZURE", "FIR_RECOMMENDED",
                                "WARNING_ISSUED", "VIDEO_RECORDED"]] = []
    seizure: SeizureIn = SeizureIn()
    media_ids: list[str] = []
    recommendation: Literal["DISPOSE", "DROP", "ESCALATE"] | None = None

    @model_validator(mode="after")
    def _seizure(self):
        if self.seizure.made and not self.seizure.items:
            raise ValueError("seizure.items required when seizure.made is true")
        return self


class SquadStatusIn(BaseModel):
    status: Literal["AVAILABLE", "BUSY", "OFF_DUTY"]


def _require_squad(user: User) -> int:
    if not user.squad_id:
        raise forbidden("You are not a member of any flying squad")
    return user.squad_id


def _my_assignment(db: Session, user: User, assignment_id: str) -> Assignment:
    squad_id = _require_squad(user)
    a = db.scalar(select(Assignment).where(Assignment.uuid == assignment_id).with_for_update())
    if a is None or a.squad_id != squad_id:
        raise not_found("Assignment")
    if not a.is_active:
        raise invalid_state("This assignment was moved to another squad", ended_reason=a.ended_reason)
    return a


def _complaint(db: Session, a: Assignment) -> Complaint:
    return db.scalar(select(Complaint).where(Complaint.id == a.complaint_id).with_for_update())


def assignment_card(a: Assignment) -> dict:
    c = a.complaint
    return {"id": a.uuid, "is_active": a.is_active, "assigned_at": a.assigned_at, "accepted_at": a.accepted_at,
            "started_at": a.started_at, "reached_at": a.reached_at, "note": a.note, "eta_min": a.eta_min,
            "complaint": {"id": c.uuid, "complaint_no": c.complaint_no, "status": c.status,
                          "violation_type": vt_out(c.violation_type), "description": c.description,
                          "latitude": c.latitude, "longitude": c.longitude, "address_text": c.address_text,
                          "current_stage": c.current_stage, "stage_deadline": c.stage_deadline}}


@router.get("/assignments", summary="F1 My squad's active and past assignments")
def my_assignments(active: bool | None = Query(True, description="true = in progress only, false = past only, "
                                                                 "omit for all"),
                   page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                   user: User = Depends(fs_only), db: Session = Depends(get_db)):
    squad_id = _require_squad(user)
    q = select(Assignment).where(Assignment.squad_id == squad_id)
    if active is True:
        q = q.where(Assignment.is_active.is_(True), Assignment.complaint.has(Complaint.status.in_(IN_PROGRESS)))
    elif active is False:
        q = q.where(~(Assignment.is_active.is_(True) & Assignment.complaint.has(Complaint.status.in_(IN_PROGRESS))))
    return paginate(db, q.order_by(Assignment.assigned_at.desc()), page, page_size, assignment_card)


@router.post("/assignments/{assignment_id}/accept", summary="F2 Accept the assignment")
def accept(assignment_id: str, user: User = Depends(fs_only), db: Session = Depends(get_db),
           meta: RequestMeta = Depends(request_meta)):
    a = _my_assignment(db, user, assignment_id)
    c = _complaint(db, a)
    transition(db, c, "ACCEPTED", user, meta)
    a.accepted_at = utcnow()
    db.commit()
    return {"status": c.status, "accepted_at": a.accepted_at}


@router.post("/assignments/{assignment_id}/start", summary="F3 Start travel; returns a navigation link")
def start(assignment_id: str, user: User = Depends(fs_only), db: Session = Depends(get_db),
          meta: RequestMeta = Depends(request_meta)):
    a = _my_assignment(db, user, assignment_id)
    c = _complaint(db, a)
    transition(db, c, "EN_ROUTE", user, meta)
    a.started_at = utcnow()
    db.commit()
    return {"status": c.status, "started_at": a.started_at, "stage_deadline": c.stage_deadline,
            "navigation_url": f"https://www.google.com/maps/dir/?api=1&destination={c.latitude},{c.longitude}"
                              f"&travelmode=driving"}


@router.post("/location", summary="F4 GPS ping (batch of points), every 30 s while on duty")
def location(body: LocationIn, user: User = Depends(fs_only), db: Session = Depends(get_db)):
    squad_id = _require_squad(user)
    now = utcnow()
    pts = sorted(body.points, key=lambda p: p.at)
    for p in pts:
        at = as_utc(p.at)
        if at > now:
            at = now
        db.add(SquadLocationLog(squad_id=squad_id, user_id=user.id, location=geo.point(p.lat, p.lng),
                                accuracy_m=p.accuracy_m, recorded_at=at))
    last = pts[-1]
    squad = db.get(FlyingSquad, squad_id)
    last_at = min(as_utc(last.at), now)
    if squad.last_location_at is None or last_at >= squad.last_location_at:
        squad.last_location = geo.point(last.lat, last.lng)
        squad.last_location_at = last_at
        queue_event(db, "squad.location", {"squad_id": squad.id, "code": squad.code, "latitude": last.lat,
                                           "longitude": last.lng, "at": iso(last_at)},
                    {"district_id": squad.district_id, "roles": ["DC", "DEO", "CEO", "ADMIN"]})
    db.commit()
    return {"accepted": len(pts)}


@router.post("/assignments/{assignment_id}/reached", summary="F5 Mark reached (must be within 200 m)")
def reached(assignment_id: str, body: GeoIn, user: User = Depends(fs_only), db: Session = Depends(get_db),
            meta: RequestMeta = Depends(request_meta)):
    a = _my_assignment(db, user, assignment_id)
    c = _complaint(db, a)
    if c.status not in ("ACCEPTED", "EN_ROUTE"):
        raise invalid_state(f"Complaint is {c.status}; accept and start travel first", current_status=c.status)
    dist = geo.distance_m_to_complaint(db, c.id, body.lat, body.lng)
    if dist > settings.REACHED_GEOFENCE_M:
        raise geo_mismatch(f"You are {round(dist)} m away from the complaint location",
                           distance_m=round(dist), allowed_m=settings.REACHED_GEOFENCE_M)
    transition(db, c, "REACHED", user, meta, audit_payload={"distance_m": round(dist)})
    a.reached_at = utcnow()
    a.reached_location = geo.point(body.lat, body.lng)
    a.reached_distance_m = round(dist)
    notify_users(db, user_ids_for(db, "DC", district_id=c.district_id), "SQUAD_REACHED",
                 f"Squad reached {c.complaint_no}", f"{a.squad.code} is at the location.", complaint=c)
    db.commit()
    return {"status": c.status, "reached_at": a.reached_at, "distance_m": round(dist),
            "stage_deadline": c.stage_deadline}


@router.post("/assignments/{assignment_id}/media", status_code=201,
             summary="F6 Upload site photo / video / panchnama / seizure memo")
def upload_squad_media(assignment_id: str,
                       file: UploadFile = File(...),
                       media_type: Literal["PHOTO", "VIDEO", "AUDIO", "DOCUMENT"] = Form(...),
                       captured_at: datetime = Form(...),
                       doc_kind: Literal["PANCHNAMA", "SEIZURE_MEMO", "STATEMENT", "OTHER"] | None = Form(None),
                       sha256: str | None = Form(None),
                       latitude: float | None = Form(None),
                       longitude: float | None = Form(None),
                       duration_sec: int | None = Form(None),
                       user: User = Depends(fs_only), db: Session = Depends(get_db)):
    a = _my_assignment(db, user, assignment_id)
    c = _complaint(db, a)
    if c.status not in ("REACHED", "REPORT_RETURNED"):
        raise invalid_state("Upload evidence after reaching the location", current_status=c.status)
    if media_type == "DOCUMENT" and not doc_kind:
        raise validation_error("doc_kind is required for DOCUMENT uploads")
    m = save_media(db, complaint=c, user=user, source="SQUAD", file=file, media_type=media_type,
                   captured_at=captured_at, sha256=sha256, latitude=latitude, longitude=longitude,
                   duration_sec=duration_sec, doc_kind=doc_kind, assignment_id=a.id)
    db.commit()
    return media_out(m)


@router.post("/assignments/{assignment_id}/report", summary="F7 Submit the field report to the RO")
def submit_report(assignment_id: str, body: ReportIn, user: User = Depends(fs_only), db: Session = Depends(get_db),
                  meta: RequestMeta = Depends(request_meta)):
    a = _my_assignment(db, user, assignment_id)
    c = _complaint(db, a)
    if c.status not in ("REACHED", "REPORT_RETURNED"):
        raise invalid_state(f"Complaint is {c.status}; a report can be submitted after reaching",
                            current_status=c.status)
    if body.media_ids:
        found = set(db.scalars(select(ComplaintMedia.uuid).where(ComplaintMedia.complaint_id == c.id,
                                                                 ComplaintMedia.uuid.in_(body.media_ids))))
        missing = [m for m in body.media_ids if m not in found]
        if missing:
            raise validation_error("Some media_ids do not belong to this complaint", missing=missing)
    last = db.scalar(select(FieldReport).where(FieldReport.assignment_id == a.id)
                     .order_by(FieldReport.version.desc()).limit(1))
    r = FieldReport(assignment_id=a.id, complaint_id=c.id, submitted_by=user.id,
                    version=(last.version + 1) if last else 1, finding=body.finding, summary=body.summary,
                    party_or_candidate=body.party_or_candidate, actions_taken=list(body.actions_taken),
                    seizure_made=body.seizure.made, recommendation=body.recommendation)
    r.seizure_items = [SeizureItem(item_type=i.type, description=i.description, quantity=i.quantity, unit=i.unit,
                                   value_inr=i.value_inr) for i in body.seizure.items]
    db.add(r)
    db.flush()
    transition(db, c, "REPORT_SUBMITTED", user, meta, remarks=body.finding,
               audit_payload={"report_version": r.version, "media_ids": body.media_ids})
    squad = db.get(FlyingSquad, a.squad_id)
    if squad.status == "BUSY":
        squad.status = "AVAILABLE"
    notify_users(db, user_ids_for(db, "RO", ac_id=c.ac_id), "REPORT_READY",
                 f"Field report ready: {c.complaint_no}", "Review and decide within 50 minutes.", complaint=c)
    db.commit()
    return {"status": c.status, "report_id": r.id, "version": r.version, "stage_deadline": c.stage_deadline}


@router.patch("/me/status", summary="F8 Set my squad's availability")
def squad_status(body: SquadStatusIn, user: User = Depends(fs_only), db: Session = Depends(get_db),
                 meta: RequestMeta = Depends(request_meta)):
    squad_id = _require_squad(user)
    squad = db.scalar(select(FlyingSquad).where(FlyingSquad.id == squad_id).with_for_update())
    busy = db.scalar(select(Assignment).where(Assignment.squad_id == squad_id, Assignment.is_active.is_(True),
                                              Assignment.complaint.has(Complaint.status.in_(
                                                  ("ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED")))).limit(1))
    if busy and body.status != "BUSY":
        raise invalid_state("Finish the current assignment first",
                            complaint_no=busy.complaint.complaint_no)
    squad.status = body.status
    from app.services.audit import write_audit
    write_audit(db, "squad", squad.id, f"STATUS_{body.status}", user, meta)
    queue_event(db, "squad.status_changed", {"squad_id": squad.id, "code": squad.code, "status": squad.status},
                {"district_id": squad.district_id, "roles": ["DC", "DEO", "CEO", "ADMIN"]})
    db.commit()
    return {"squad": squad.code, "status": squad.status}
