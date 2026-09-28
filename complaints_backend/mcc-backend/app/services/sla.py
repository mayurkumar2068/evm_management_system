"""Stage SLA timers: 5 min allocation, 15 min travel, 30 min enquiry, 50 min RO decision.

One complaint_stage_sla row per (complaint, stage). Targets come from sla_config (API M9).
"""
import logging
from datetime import timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.timeutil import iso, utcnow
from app.db.session import queue_event
from app.models import Assignment, Complaint, ComplaintStageSla, SlaConfig
from app.services.notify import notify_users, user_ids_for

log = logging.getLogger("sla")

STAGES = ("ALLOCATION", "TRAVEL", "ENQUIRY", "RO_DECISION")
STAGE_OWNER = {"ALLOCATION": "DC", "TRAVEL": "FS", "ENQUIRY": "FS", "RO_DECISION": "RO"}
DEFAULT_TARGETS = {"ALLOCATION": 5, "TRAVEL": 15, "ENQUIRY": 30, "RO_DECISION": 50}


def load_config(db: Session) -> dict[str, SlaConfig]:
    rows = {r.stage: r for r in db.scalars(select(SlaConfig))}
    for stage, minutes in DEFAULT_TARGETS.items():
        rows.setdefault(stage, SlaConfig(stage=stage, target_min=minutes, warn_pct=80,
                                         escalate_to_role="DEO" if stage == "RO_DECISION" else "DC"))
    return rows


def total_target_minutes(db: Session) -> int:
    return sum(c.target_min for c in load_config(db).values())


def get_stage(db: Session, complaint_id: int, stage: str) -> ComplaintStageSla | None:
    return db.scalar(select(ComplaintStageSla).where(ComplaintStageSla.complaint_id == complaint_id,
                                                     ComplaintStageSla.stage == stage))


def open_stage(db: Session, complaint: Complaint, stage: str) -> ComplaintStageSla:
    now = utcnow()
    target = load_config(db)[stage].target_min
    row = get_stage(db, complaint.id, stage)
    if row is None:
        row = ComplaintStageSla(complaint_id=complaint.id, stage=stage, owner_role=STAGE_OWNER[stage],
                                started_at=now, deadline_at=now + timedelta(minutes=target))
        db.add(row)
    elif row.ended_at is not None:  # re-opened (e.g. DEO returned the case to the RO)
        row.started_at, row.deadline_at = now, now + timedelta(minutes=target)
        row.ended_at = row.duration_sec = row.warned_at = row.breached_at = None
    complaint.current_stage = stage
    complaint.stage_deadline = row.deadline_at
    return row


def close_stage(db: Session, complaint: Complaint, stage: str) -> None:
    row = get_stage(db, complaint.id, stage)
    if row is None or row.ended_at is not None:
        return
    now = utcnow()
    row.ended_at = now
    row.duration_sec = int((now - row.started_at).total_seconds())
    if now > row.deadline_at:
        row.breached_at = row.breached_at or now
        complaint.is_sla_breached = True
    if complaint.current_stage == stage:
        complaint.current_stage = None
        complaint.stage_deadline = None


def close_all_open(db: Session, complaint: Complaint) -> None:
    for stage in STAGES:
        close_stage(db, complaint, stage)


def _owner_user_ids(db: Session, row: ComplaintStageSla) -> list[int]:
    c = row.complaint
    if row.owner_role == "DC":
        return user_ids_for(db, "DC", district_id=c.district_id)
    if row.owner_role == "RO":
        return user_ids_for(db, "RO", ac_id=c.ac_id)
    asg = db.scalar(select(Assignment).where(Assignment.complaint_id == c.id, Assignment.is_active.is_(True)))
    return user_ids_for(db, "FS", squad_id=asg.squad_id) if asg else []


def run_sla_check(db: Session) -> dict:
    """Send sla.warning at warn_pct of target and sla.breached at 100%. Idempotent."""
    now = utcnow()
    cfg = load_config(db)
    warned = breached = 0
    rows = db.scalars(select(ComplaintStageSla).where(
        ComplaintStageSla.ended_at.is_(None), ComplaintStageSla.breached_at.is_(None),
        ComplaintStageSla.started_at <= now)).all()
    for row in rows:
        c = row.complaint
        scope = {"district_id": c.district_id, "ac_id": c.ac_id, "roles": ["DC", "DEO", "CEO", "RO", "FS", "ADMIN"]}
        total = (row.deadline_at - row.started_at).total_seconds()
        warn_at = row.started_at + timedelta(seconds=total * cfg[row.stage].warn_pct / 100)
        info = {"complaint_id": c.uuid, "complaint_no": c.complaint_no, "stage": row.stage,
                "deadline": iso(row.deadline_at)}
        if now >= row.deadline_at:
            row.breached_at = now
            row.warned_at = row.warned_at or now
            c.is_sla_breached = True
            targets = _owner_user_ids(db, row)
            esc = cfg[row.stage].escalate_to_role
            if esc:
                targets += user_ids_for(db, esc, district_id=c.district_id)
            notify_users(db, targets, "SLA_BREACHED", f"SLA breached: {c.complaint_no}",
                         f"{row.stage.replace('_', ' ').title()} stage crossed its "
                         f"{cfg[row.stage].target_min} min target", complaint=c, data={"stage": row.stage})
            queue_event(db, "sla.breached", info, scope)
            breached += 1
        elif row.warned_at is None and now >= warn_at:
            row.warned_at = now
            notify_users(db, _owner_user_ids(db, row), "SLA_WARNING", f"SLA warning: {c.complaint_no}",
                         f"{row.stage.replace('_', ' ').title()} stage is close to its "
                         f"{cfg[row.stage].target_min} min target", complaint=c, data={"stage": row.stage})
            queue_event(db, "sla.warning", info, scope)
            warned += 1
    db.commit()
    if warned or breached:
        log.info("SLA check: %d warnings, %d breaches", warned, breached)
    return {"warned": warned, "breached": breached}
