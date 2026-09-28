"""Module C: Citizen (7 APIs)."""
from datetime import datetime, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, File, Form, Query, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy import cast, func, select
from sqlalchemy.dialects.mysql import INTEGER
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import RequestMeta, get_current_user, request_meta, require_roles
from app.core.errors import geo_mismatch, invalid_state, not_found, rate_limited, validation_error
from app.core.security import new_uuid
from app.core.timeutil import iso, as_utc, utcnow
from app.db.session import get_db, queue_event
from app.models import Complaint, ComplaintMedia, District, User, ViolationType
from app.services import geo, sla
from app.services.access import get_complaint
from app.services.audit import write_audit
from app.services.media import media_out, save_media
from app.services.serializers import citizen_view, paginate, vt_out
from app.services.state_machine import ensure_status, transition

router = APIRouter(tags=["C. Citizen"])
citizen_only = require_roles("CITIZEN")


class ComplaintCreateIn(BaseModel):
    violation_type: str = Field(examples=["LIQUOR_DISTRIBUTION"])
    description: str | None = Field(default=None, max_length=2000)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    gps_accuracy_m: int | None = Field(default=None, ge=0, le=5000)
    captured_at: datetime
    is_anonymous: bool = False
    language: Literal["hi", "en"] = "hi"
    address_text: str | None = Field(default=None, max_length=255)


def _own_complaint(db: Session, user: User, ident: str, for_update: bool = False) -> Complaint:
    c = get_complaint(db, ident, for_update=for_update)
    if c.citizen_id != user.id:
        raise not_found("Complaint")
    return c


@router.get("/violation-types", summary="C1 List of MCC violation categories (Hindi + English)")
def violation_types(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    rows = db.scalars(select(ViolationType).where(ViolationType.is_active.is_(True))
                      .order_by(ViolationType.sort_order)).all()
    return {"results": [vt_out(v) for v in rows]}


@router.post("/complaints", status_code=201, summary="C2 Create a draft complaint")
def create_complaint(body: ComplaintCreateIn, user: User = Depends(citizen_only), db: Session = Depends(get_db),
                     meta: RequestMeta = Depends(request_meta)):
    since = utcnow() - timedelta(hours=1)
    recent = db.scalar(select(func.count()).select_from(Complaint)
                       .where(Complaint.citizen_id == user.id, Complaint.created_at >= since))
    if recent >= settings.CITIZEN_MAX_COMPLAINTS_PER_HOUR:
        raise rate_limited(f"Maximum {settings.CITIZEN_MAX_COMPLAINTS_PER_HOUR} complaints per hour")
    vt = db.scalar(select(ViolationType).where(ViolationType.code == body.violation_type,
                                               ViolationType.is_active.is_(True)))
    if vt is None:
        raise validation_error("Unknown violation_type", field="violation_type")
    captured = as_utc(body.captured_at)
    now = utcnow()
    if captured > now + timedelta(minutes=2):
        raise validation_error("captured_at is in the future")
    if now - captured > timedelta(seconds=settings.CAPTURE_UPLOAD_WINDOW_SECONDS):
        raise validation_error("Capture is older than 5 minutes. Please capture again in the app")
    c = Complaint(uuid=new_uuid(), citizen_id=user.id, is_anonymous=body.is_anonymous, violation_type_id=vt.id,
                  description=body.description, language=body.language, latitude=body.latitude,
                  longitude=body.longitude, gps_accuracy_m=body.gps_accuracy_m, address_text=body.address_text,
                  status="DRAFT", captured_at=captured,
                  upload_deadline=captured + timedelta(seconds=settings.CAPTURE_UPLOAD_WINDOW_SECONDS))
    db.add(c)
    db.flush()
    write_audit(db, "complaint", c.id, "CREATE_DRAFT", user, meta)
    db.commit()
    return {"id": c.uuid, "status": c.status, "upload_deadline": c.upload_deadline}


@router.post("/complaints/{complaint_id}/media", status_code=201, summary="C3 Upload one photo / video (live capture)")
def upload_citizen_media(complaint_id: str,
                         file: UploadFile = File(...),
                         media_type: Literal["PHOTO", "VIDEO", "AUDIO"] = Form(...),
                         captured_at: datetime = Form(...),
                         sha256: str | None = Form(None),
                         latitude: float | None = Form(None),
                         longitude: float | None = Form(None),
                         duration_sec: int | None = Form(None),
                         user: User = Depends(citizen_only), db: Session = Depends(get_db)):
    c = _own_complaint(db, user, complaint_id, for_update=True)
    ensure_status(c, "DRAFT")
    m = save_media(db, complaint=c, user=user, source="CITIZEN", file=file, media_type=media_type,
                   captured_at=captured_at, sha256=sha256, latitude=latitude, longitude=longitude,
                   duration_sec=duration_sec, enforce_fresh=True)
    db.commit()
    return media_out(m)


UNSIGNED = INTEGER(unsigned=True)


def _next_complaint_no(db: Session, district: District) -> str:
    # Lock the district row so two submits cannot get the same sequence number
    db.execute(select(District.id).where(District.id == district.id).with_for_update())
    yy = utcnow().strftime("%y")
    prefix = f"{district.code}-{yy}-"
    seq_expr = cast(func.substring_index(Complaint.complaint_no, "-", -1), UNSIGNED)
    last = db.scalar(select(func.max(seq_expr)).where(Complaint.complaint_no.like(f"{prefix}%")))
    seq = int(last) + 1 if last else 1
    return f"{prefix}{seq:04d}"


@router.post("/complaints/{complaint_id}/submit", summary="C4 Final submit: geo + duplicate checks, SLA clock starts")
def submit_complaint(complaint_id: str, user: User = Depends(citizen_only), db: Session = Depends(get_db),
                     meta: RequestMeta = Depends(request_meta)):
    c = _own_complaint(db, user, complaint_id, for_update=True)
    ensure_status(c, "DRAFT")
    media_count = db.scalar(select(func.count()).select_from(ComplaintMedia)
                            .where(ComplaintMedia.complaint_id == c.id, ComplaintMedia.source == "CITIZEN"))
    if media_count == 0:
        raise validation_error("Attach at least one photo or video before submitting")
    district, ac = geo.resolve_district_ac(db, c.latitude, c.longitude)
    if district is None:
        raise geo_mismatch("Location is outside the districts covered by this system",
                           latitude=c.latitude, longitude=c.longitude)
    now = utcnow()
    c.district_id, c.ac_id = district.id, ac.id if ac else None
    c.complaint_no = _next_complaint_no(db, district)
    c.submitted_at = now
    c.sla_deadline = now + timedelta(minutes=sla.total_target_minutes(db))
    dup = geo.find_possible_duplicate(db, c)
    transition(db, c, "RECEIVED", user, meta, audit_payload={"possible_duplicate_of": dup.complaint_no if dup else None})
    queue_event(db, "complaint.created",
                {"complaint_id": c.uuid, "complaint_no": c.complaint_no, "violation_type": c.violation_type.code,
                 "latitude": c.latitude, "longitude": c.longitude, "ac": ac.code if ac else None,
                 "possible_duplicate_of": dup.complaint_no if dup else None, "stage_deadline": iso(c.stage_deadline)},
                {"district_id": c.district_id, "ac_id": c.ac_id, "roles": ["DC", "DEO", "CEO", "ADMIN"]})
    db.commit()
    return {"id": c.uuid, "complaint_no": c.complaint_no, "status": c.status,
            "district": district.code, "ac": {"code": ac.code, "name": ac.name_en} if ac else None,
            "sla_deadline": c.sla_deadline, "duplicate_of": dup.complaint_no if dup else None}


@router.post("/complaints/{complaint_id}/withdraw", summary="C5 Withdraw before a squad is assigned")
def withdraw(complaint_id: str, user: User = Depends(citizen_only), db: Session = Depends(get_db),
             meta: RequestMeta = Depends(request_meta)):
    c = _own_complaint(db, user, complaint_id, for_update=True)
    if c.status not in ("DRAFT", "RECEIVED"):
        raise invalid_state("A squad is already assigned; the complaint can no longer be withdrawn",
                            current_status=c.status)
    transition(db, c, "WITHDRAWN", user, meta)
    db.commit()
    return {"id": c.uuid, "status": c.status}


@router.get("/citizen/complaints", summary="C6 My complaints with current status")
def my_complaints(page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                  user: User = Depends(citizen_only), db: Session = Depends(get_db)):
    q = select(Complaint).where(Complaint.citizen_id == user.id).order_by(Complaint.created_at.desc())
    return paginate(db, q, page, page_size, lambda c: {
        "id": c.uuid, "complaint_no": c.complaint_no, "status": c.status,
        "violation_type": vt_out(c.violation_type), "created_at": c.created_at, "submitted_at": c.submitted_at,
        "closed_at": c.closed_at})


@router.get("/citizen/complaints/{complaint_id}", summary="C7 Status timeline and final remarks (no officer identity)")
def my_complaint(complaint_id: str, user: User = Depends(citizen_only), db: Session = Depends(get_db)):
    return citizen_view(db, _own_complaint(db, user, complaint_id))
