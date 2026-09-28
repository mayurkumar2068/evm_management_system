"""Module E: Escalation (3 APIs) for DEO (district) and CEO (state; also tracks ECI-level cases)."""
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field, model_validator
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import RequestMeta, request_meta, require_roles
from app.core.errors import forbidden, invalid_state, not_found
from app.core.timeutil import utcnow
from app.db.session import get_db
from app.models import Complaint, Decision, Escalation, User
from app.services.notify import notify_users, user_ids_for
from app.services.serializers import complaint_detail, complaint_summary, escalation_out, paginate
from app.services.state_machine import transition

router = APIRouter(prefix="/escalations", tags=["E. Escalation"])
esc_roles = require_roles("DEO", "CEO", "ADMIN")

LEVELS_FOR_ROLE = {"DEO": ("DEO",), "CEO": ("CEO", "ECI"), "ADMIN": ("DEO", "CEO", "ECI")}
NEXT_LEVEL = {"DEO": "CEO", "CEO": "ECI"}


class EscalationActionIn(BaseModel):
    action: Literal["RESOLVE", "FORWARD", "RETURN_TO_RO"]
    final_action: str | None = Field(default=None, max_length=100,
                                     description="Required for RESOLVE, e.g. FIR_REGISTERED, NOTICE_ISSUED")
    remarks: str = Field(min_length=10, max_length=500)

    @model_validator(mode="after")
    def _check(self):
        if self.action == "RESOLVE" and not self.final_action:
            raise ValueError("final_action is required for RESOLVE")
        return self


def _scoped(q, user: User):
    q = q.where(Escalation.level.in_(LEVELS_FOR_ROLE[user.role]))
    if user.role == "DEO":
        q = q.where(Escalation.complaint.has(Complaint.district_id == (user.district_id or -1)))
    return q


def _get(db: Session, user: User, escalation_id: int, lock: bool = False) -> Escalation:
    q = _scoped(select(Escalation).where(Escalation.id == escalation_id), user)
    if lock:
        q = q.with_for_update()
    e = db.scalar(q)
    if e is None:
        raise not_found("Escalation")
    return e


@router.get("", summary="E1 Escalated cases for DEO (district) or CEO (state)")
def list_escalations(state: Literal["open", "closed", "all"] = "open",
                     page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
                     user: User = Depends(esc_roles), db: Session = Depends(get_db)):
    q = _scoped(select(Escalation), user)
    if state == "open":
        q = q.where(Escalation.closed_at.is_(None))
    elif state == "closed":
        q = q.where(Escalation.closed_at.is_not(None))
    return paginate(db, q.order_by(Escalation.created_at), page, page_size,
                    lambda e: {**escalation_out(e), "complaint": complaint_summary(e.complaint)})


@router.get("/{escalation_id}", summary="E2 Escalation with full case, RO remarks and all evidence")
def get_escalation(escalation_id: int, user: User = Depends(esc_roles), db: Session = Depends(get_db)):
    e = _get(db, user, escalation_id)
    chain = db.scalars(select(Escalation).where(Escalation.complaint_id == e.complaint_id)
                       .order_by(Escalation.created_at)).all()
    return {**escalation_out(e), "chain": [escalation_out(x) for x in chain],
            "complaint": complaint_detail(db, e.complaint, user)}


@router.post("/{escalation_id}/action", summary="E3 RESOLVE, FORWARD (DEO → CEO → ECI) or RETURN_TO_RO")
def act(escalation_id: int, body: EscalationActionIn, user: User = Depends(esc_roles), db: Session = Depends(get_db),
        meta: RequestMeta = Depends(request_meta)):
    e = _get(db, user, escalation_id, lock=True)
    if e.closed_at is not None:
        raise invalid_state("This escalation is already closed", action=e.action)
    if user.role == "CEO" and e.level == "ECI" and body.action == "FORWARD":
        raise forbidden("ECI is the last level")
    c = db.scalar(select(Complaint).where(Complaint.id == e.complaint_id).with_for_update())
    if c.status != "ESCALATED":
        raise invalid_state(f"Complaint is {c.status}", current_status=c.status)
    now = utcnow()
    e.action, e.action_remarks, e.action_by, e.closed_at = body.action, body.remarks, user.id, now
    out: dict = {"escalation_id": e.id, "action": body.action}

    if body.action == "RESOLVE":
        e.final_action = body.final_action
        transition(db, c, "RESOLVED", user, meta, remarks=body.remarks,
                   audit_payload={"escalation_id": e.id, "final_action": body.final_action})
    elif body.action == "FORWARD":
        nxt = NEXT_LEVEL.get(e.level)
        if nxt is None:
            raise invalid_state("ECI is the last level")
        assignee = user_ids_for(db, "CEO")
        new = Escalation(complaint_id=c.id, parent_id=e.id, level=nxt, raised_by=user.id,
                         raised_remarks=body.remarks, assigned_to=assignee[0] if assignee else None)
        db.add(new)
        db.flush()
        notify_users(db, assignee, "ESCALATION_NEW", f"Escalated to {nxt}: {c.complaint_no}", body.remarks,
                     complaint=c, data={"escalation_id": new.id, "level": nxt})
        from app.services.audit import write_audit
        write_audit(db, "escalation", e.id, f"FORWARD_{nxt}", user, meta, {"new_escalation_id": new.id})
        out["new_escalation"] = {"id": new.id, "level": nxt}
    else:  # RETURN_TO_RO: RO must decide again; the decision stage timer restarts
        for d in db.scalars(select(Decision).where(Decision.complaint_id == c.id, Decision.is_current.is_(True))):
            d.is_current = False
        transition(db, c, "REPORT_SUBMITTED", user, meta, remarks=body.remarks,
                   audit_payload={"escalation_id": e.id, "returned_to_ro": True})
        notify_users(db, user_ids_for(db, "RO", ac_id=c.ac_id), "ESCALATION_RETURNED",
                     f"Returned by {e.level}: {c.complaint_no}", body.remarks, complaint=c)
    db.commit()
    out["complaint_status"] = c.status
    return out
