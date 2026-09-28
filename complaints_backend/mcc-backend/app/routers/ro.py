"""Module R: Returning Officer (5 APIs)."""
from datetime import datetime
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import RequestMeta, request_meta, require_roles
from app.core.errors import not_found
from app.core.timeutil import minutes_between, as_utc, utcnow
from app.db.session import get_db
from app.models import Complaint, ComplaintMedia, Decision, Escalation, FieldReport, User
from app.services import sla
from app.services.access import assert_can_view, get_complaint
from app.services.media import media_out
from app.services.notify import notify_users, user_ids_for
from app.services.serializers import (active_squad_codes, complaint_summary, decision_out, paginate, report_out,
                                      stages_out, summaries)
from app.services.state_machine import active_assignment, ensure_status, transition

router = APIRouter(prefix="/ro", tags=["R. Returning Officer"])
ro_only = require_roles("RO")

ESCALATION_ROLE = {"DEO": "DEO", "CEO": "CEO", "ECI": "CEO"}  # ECI cases are tracked by the CEO office


class DecisionIn(BaseModel):
    action: Literal["DISPOSE", "DROP", "ESCALATE"]
    final_action: Literal["WARNING_ISSUED", "MATERIAL_REMOVED", "SEIZURE", "FIR_REGISTERED",
                          "NOTICE_TO_CANDIDATE"] | None = None
    fir_no: str | None = Field(default=None, max_length=50)
    reason_code: Literal["NOTHING_FOUND", "NOT_MCC", "DUPLICATE", "FAKE_EVIDENCE"] | None = None
    escalate_to: Literal["DEO", "CEO", "ECI"] | None = None
    remarks: str = Field(min_length=10, max_length=500)

    @model_validator(mode="after")
    def _required_by_action(self):
        need = {"DISPOSE": ("final_action", self.final_action), "DROP": ("reason_code", self.reason_code),
                "ESCALATE": ("escalate_to", self.escalate_to)}[self.action]
        if need[1] is None:
            raise ValueError(f"{need[0]} is required when action is {self.action}")
        if self.final_action == "FIR_REGISTERED" and not self.fir_no:
            raise ValueError("fir_no is required when final_action is FIR_REGISTERED")
        return self


class SendBackIn(BaseModel):
    remarks: str = Field(min_length=10, max_length=500)


def _ro_complaint(db: Session, user: User, ident: str, lock: bool = False) -> Complaint:
    c = get_complaint(db, ident, for_update=lock)
    assert_can_view(db, user, c)
    return c


@router.get("/complaints", summary="R1 Decision queue for my AC, oldest SLA first")
def ro_queue(status: Literal["REPORT_SUBMITTED", "REPORT_RETURNED", "ALL_OPEN"] = "REPORT_SUBMITTED",
             page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
             user: User = Depends(ro_only), db: Session = Depends(get_db)):
    statuses = ["REPORT_SUBMITTED"] if status == "REPORT_SUBMITTED" else \
        ["REPORT_RETURNED"] if status == "REPORT_RETURNED" else \
        ["RECEIVED", "ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED", "REPORT_SUBMITTED", "REPORT_RETURNED"]
    q = (select(Complaint).where(Complaint.ac_id == (user.ac_id or -1), Complaint.status.in_(statuses))
         .order_by(Complaint.stage_deadline.is_(None), Complaint.stage_deadline))
    data = paginate(db, q, page, page_size, lambda c: c)
    data["results"] = summaries(db, data["results"])
    return data


@router.get("/complaints/{complaint_id}/field-report", summary="R2 Field report, evidence and time per stage")
def field_report(complaint_id: str, user: User = Depends(ro_only), db: Session = Depends(get_db)):
    c = _ro_complaint(db, user, complaint_id)
    reports = db.scalars(select(FieldReport).where(FieldReport.complaint_id == c.id)
                         .order_by(FieldReport.version.desc())).all()
    if not reports:
        raise not_found("Field report")
    media = db.scalars(select(ComplaintMedia).where(ComplaintMedia.complaint_id == c.id)
                       .order_by(ComplaintMedia.source, ComplaintMedia.captured_at)).all()
    squad = active_squad_codes(db, [c.id]).get(c.id)
    return {"complaint": {**complaint_summary(c, squad), "description": c.description},
            "report": report_out(reports[0]), "previous_versions": [report_out(r) for r in reports[1:]],
            "media": {"citizen": [media_out(m) for m in media if m.source == "CITIZEN"],
                      "squad": [media_out(m) for m in media if m.source == "SQUAD"]},
            "stages": stages_out(db, c.id)}


@router.post("/complaints/{complaint_id}/decision", summary="R3 Dispose, Drop or Escalate; notifies the citizen")
def decide(complaint_id: str, body: DecisionIn, user: User = Depends(ro_only), db: Session = Depends(get_db),
           meta: RequestMeta = Depends(request_meta)):
    c = _ro_complaint(db, user, complaint_id, lock=True)
    ensure_status(c, "REPORT_SUBMITTED")
    report = db.scalar(select(FieldReport).where(FieldReport.complaint_id == c.id)
                       .order_by(FieldReport.version.desc()).limit(1))
    now = utcnow()
    total = minutes_between(c.submitted_at, now) if c.submitted_at else None
    sla_met = c.sla_deadline is not None and now <= c.sla_deadline  # overall 100-min target
    for old in db.scalars(select(Decision).where(Decision.complaint_id == c.id, Decision.is_current.is_(True))):
        old.is_current = False
    d = Decision(complaint_id=c.id, field_report_id=report.id if report else None, decided_by=user.id,
                 action=body.action, final_action=body.final_action if body.action == "DISPOSE" else None,
                 fir_no=body.fir_no if body.action == "DISPOSE" else None,
                 reason_code=body.reason_code if body.action == "DROP" else None,
                 escalate_to=body.escalate_to if body.action == "ESCALATE" else None,
                 remarks=body.remarks, total_minutes=total, sla_met=sla_met, decided_at=now)
    db.add(d)
    to = {"DISPOSE": "DISPOSED", "DROP": "DROPPED", "ESCALATE": "ESCALATED"}[body.action]
    if body.action == "ESCALATE":
        role = ESCALATION_ROLE[body.escalate_to]
        assignee = user_ids_for(db, role, district_id=c.district_id if role == "DEO" else None)
        esc = Escalation(complaint_id=c.id, level=body.escalate_to, raised_by=user.id, raised_remarks=body.remarks,
                         assigned_to=assignee[0] if assignee else None)
        db.add(esc)
        db.flush()
        notify_users(db, assignee, "ESCALATION_NEW", f"Escalated: {c.complaint_no}", body.remarks, complaint=c,
                     data={"escalation_id": esc.id, "level": esc.level})
    transition(db, c, to, user, meta, remarks=body.remarks, audit_payload={"decision": body.model_dump()})
    asg = active_assignment(db, c.id)
    if asg and to in ("DISPOSED", "DROPPED"):
        asg.ended_reason, asg.ended_at = "COMPLETED", now
    db.commit()
    return {"status": c.status, "decided_at": d.decided_at, "total_minutes": total, "sla_met": sla_met,
            "citizen_notified": True}


@router.post("/complaints/{complaint_id}/send-back", summary="R4 Return the report to the squad for more details")
def send_back(complaint_id: str, body: SendBackIn, user: User = Depends(ro_only), db: Session = Depends(get_db),
              meta: RequestMeta = Depends(request_meta)):
    c = _ro_complaint(db, user, complaint_id, lock=True)
    ensure_status(c, "REPORT_SUBMITTED")
    report = db.scalar(select(FieldReport).where(FieldReport.complaint_id == c.id)
                       .order_by(FieldReport.version.desc()).limit(1))
    report.returned_by_ro_id, report.returned_remarks, report.returned_at = user.id, body.remarks, utcnow()
    transition(db, c, "REPORT_RETURNED", user, meta, remarks=body.remarks)
    asg = active_assignment(db, c.id)
    if asg:
        notify_users(db, user_ids_for(db, "FS", squad_id=asg.squad_id), "REPORT_RETURNED",
                     f"RO needs more details: {c.complaint_no}", body.remarks, complaint=c,
                     data={"assignment_id": asg.uuid})
    db.commit()
    return {"status": c.status, "stage_deadline": c.stage_deadline}


@router.get("/decisions", summary="R5 My past decisions")
def my_decisions(action: Literal["DISPOSE", "DROP", "ESCALATE"] | None = None,
                 date_from: datetime | None = Query(None, alias="from"),
                 date_to: datetime | None = Query(None, alias="to"),
                 page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                 user: User = Depends(ro_only), db: Session = Depends(get_db)):
    q = select(Decision).where(Decision.decided_by == user.id)
    if action:
        q = q.where(Decision.action == action)
    if date_from:
        q = q.where(Decision.decided_at >= as_utc(date_from))
    if date_to:
        q = q.where(Decision.decided_at <= as_utc(date_to))
    return paginate(db, q.order_by(Decision.decided_at.desc()), page, page_size,
                    lambda d: {"complaint_no": d.complaint.complaint_no, "complaint_id": d.complaint.uuid,
                               "status": d.complaint.status, **decision_out(d)})


__all__ = ["router", "sla"]
