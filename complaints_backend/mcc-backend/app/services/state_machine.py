"""Complaint status state machine.

Every status change goes through `transition()`, which:
  1. rejects transitions not in TRANSITIONS (409 INVALID_STATE)
  2. opens / closes the SLA stage timers
  3. writes status_history + audit_log
  4. notifies the citizen (in-app + push) for citizen-visible steps
  5. queues a `complaint.status_changed` WebSocket event (sent after commit)
"""
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import RequestMeta
from app.core.errors import invalid_state
from app.core.timeutil import iso, utcnow
from app.db.session import queue_event
from app.models import Assignment, Complaint, StatusHistory, User
from app.services import sla
from app.services.audit import write_audit
from app.services.notify import notify_users

TRANSITIONS: dict[str, set[str]] = {
    "DRAFT": {"RECEIVED", "WITHDRAWN"},
    "RECEIVED": {"ASSIGNED", "DUPLICATE", "DROPPED_AT_DC", "WITHDRAWN"},
    "ASSIGNED": {"ACCEPTED", "ASSIGNED"},                 # ASSIGNED -> ASSIGNED = reassign (D5)
    "ACCEPTED": {"EN_ROUTE", "REACHED", "ASSIGNED"},
    "EN_ROUTE": {"REACHED", "ASSIGNED"},
    "REACHED": {"REPORT_SUBMITTED"},
    "REPORT_SUBMITTED": {"REPORT_RETURNED", "DISPOSED", "DROPPED", "ESCALATED"},
    "REPORT_RETURNED": {"REPORT_SUBMITTED"},
    "ESCALATED": {"RESOLVED", "REPORT_SUBMITTED"},       # REPORT_SUBMITTED = returned to RO (E3)
}

CLOSED_STATUSES = {"WITHDRAWN", "DUPLICATE", "DROPPED_AT_DC", "DISPOSED", "DROPPED", "RESOLVED"}
OPEN_STATUSES = {"RECEIVED", "ASSIGNED", "ACCEPTED", "EN_ROUTE", "REACHED", "REPORT_SUBMITTED",
                 "REPORT_RETURNED", "ESCALATED"}

# What the citizen sees in their timeline (C7) and gets notified about.
CITIZEN_MESSAGES: dict[str, tuple[str, str]] = {
    "RECEIVED": ("Complaint received", "Your complaint {no} has been received by the District Control Room."),
    "ASSIGNED": ("Flying squad assigned", "A flying squad has been sent for complaint {no}."),
    "REACHED": ("Squad reached the spot", "The flying squad has reached the location of complaint {no}."),
    "REPORT_SUBMITTED": ("Enquiry completed", "The enquiry for complaint {no} is complete and under review."),
    "DISPOSED": ("Action taken", "Complaint {no} is closed. Action has been taken."),
    "DROPPED": ("Complaint closed", "Complaint {no} was closed after enquiry."),
    "DROPPED_AT_DC": ("Complaint closed", "Complaint {no} could not be taken up."),
    "DUPLICATE": ("Already reported", "Complaint {no} was already reported by someone else and is being handled."),
    "ESCALATED": ("Sent to higher authority", "Complaint {no} has been sent to a higher authority."),
    "RESOLVED": ("Action taken", "Complaint {no} is closed by the higher authority."),
    "WITHDRAWN": ("Complaint withdrawn", "You withdrew complaint {no}."),
}
CITIZEN_VISIBLE = set(CITIZEN_MESSAGES)


def active_assignment(db: Session, complaint_id: int) -> Assignment | None:
    return db.scalar(select(Assignment).where(Assignment.complaint_id == complaint_id,
                                              Assignment.is_active.is_(True)))


def ensure_status(complaint: Complaint, *allowed: str) -> None:
    if complaint.status not in allowed:
        raise invalid_state(f"Complaint is {complaint.status}; expected {' or '.join(allowed)}",
                            current_status=complaint.status)


def _apply_stage_effects(db: Session, c: Complaint, to: str) -> None:
    if to == "RECEIVED":
        sla.open_stage(db, c, "ALLOCATION")
    elif to == "ASSIGNED":
        sla.close_stage(db, c, "ALLOCATION")
        sla.open_stage(db, c, "TRAVEL")
    elif to == "REACHED":
        sla.close_stage(db, c, "TRAVEL")
        sla.open_stage(db, c, "ENQUIRY")
    elif to == "REPORT_SUBMITTED":
        sla.close_stage(db, c, "ENQUIRY")
        sla.open_stage(db, c, "RO_DECISION")
    elif to in ("DISPOSED", "DROPPED", "ESCALATED"):
        sla.close_stage(db, c, "RO_DECISION")
    elif to in CLOSED_STATUSES:
        sla.close_all_open(db, c)
    # ACCEPTED / EN_ROUTE / REPORT_RETURNED: current stage timer keeps running


def transition(db: Session, c: Complaint, to: str, actor: User | None, meta: RequestMeta | None = None,
               remarks: str | None = None, audit_payload: dict | None = None) -> None:
    frm = c.status
    if to not in TRANSITIONS.get(frm, set()):
        raise invalid_state(f"Cannot move complaint from {frm} to {to}", current_status=frm)
    c.status = to
    _apply_stage_effects(db, c, to)
    if to in CLOSED_STATUSES:
        c.closed_at = utcnow()
    if to == "ESCALATED":
        c.current_stage, c.stage_deadline = None, None

    role = actor.role if actor else "SYSTEM"
    db.add(StatusHistory(complaint_id=c.id, from_status=frm, to_status=to,
                         actor_id=actor.id if actor else None, actor_role=role, remarks=remarks))
    write_audit(db, "complaint", c.id, f"STATUS_{to}", actor, meta,
                {"from": frm, "to": to, "remarks": remarks, **(audit_payload or {})})

    if to in CITIZEN_VISIBLE and frm != to:
        title, body = CITIZEN_MESSAGES[to]
        notify_users(db, [c.citizen_id], "STATUS_CHANGED", title, body.format(no=c.complaint_no or ""),
                     complaint=c, data={"status": to})

    asg = active_assignment(db, c.id)
    queue_event(db, "complaint.status_changed",
                {"complaint_id": c.uuid, "complaint_no": c.complaint_no, "from": frm, "to": to,
                 "stage": c.current_stage, "stage_deadline": iso(c.stage_deadline), "at": iso(utcnow())},
                {"district_id": c.district_id, "ac_id": c.ac_id, "squad_id": asg.squad_id if asg else None,
                 "roles": ["DC", "FS", "RO", "DEO", "CEO", "ADMIN"]})
