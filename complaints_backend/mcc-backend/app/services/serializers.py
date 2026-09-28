from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.timeutil import utcnow
from app.models import (Assignment, Complaint, ComplaintMedia, ComplaintStageSla, Decision, Escalation,
                        FieldReport, FlyingSquad, StatusHistory, User)
from app.services.media import media_out
from app.services.state_machine import CITIZEN_MESSAGES


def paginate(db: Session, q, page: int, page_size: int, serialize) -> dict:
    page = max(1, page)
    page_size = max(1, min(page_size, 100))
    total = db.scalar(select(func.count()).select_from(q.order_by(None).subquery()))
    rows = db.scalars(q.limit(page_size).offset((page - 1) * page_size)).unique().all()
    return {"count": total, "page": page, "page_size": page_size,
            "next": page + 1 if page * page_size < total else None,
            "previous": page - 1 if page > 1 else None,
            "results": [serialize(r) for r in rows]}


def vt_out(vt) -> dict:
    return {"code": vt.code, "name_en": vt.name_en, "name_hi": vt.name_hi}


def active_squad_codes(db: Session, complaint_ids: list[int]) -> dict[int, str]:
    if not complaint_ids:
        return {}
    rows = db.execute(select(Assignment.complaint_id, FlyingSquad.code)
                      .join(FlyingSquad, FlyingSquad.id == Assignment.squad_id)
                      .where(Assignment.complaint_id.in_(complaint_ids), Assignment.is_active.is_(True)))
    return {cid: code for cid, code in rows}


def complaint_summary(c: Complaint, squad_code: str | None = None) -> dict:
    left = int((c.stage_deadline - utcnow()).total_seconds()) if c.stage_deadline else None
    return {
        "id": c.uuid, "complaint_no": c.complaint_no, "status": c.status,
        "violation_type": vt_out(c.violation_type),
        "district": c.district.code if c.district else None,
        "ac": {"code": c.ac.code, "name": c.ac.name_en} if c.ac else None,
        "address_text": c.address_text, "latitude": c.latitude, "longitude": c.longitude,
        "current_stage": c.current_stage, "stage_deadline": c.stage_deadline, "seconds_left": left,
        "is_sla_breached": c.is_sla_breached, "squad": squad_code,
        "submitted_at": c.submitted_at, "closed_at": c.closed_at,
    }


def summaries(db: Session, complaints: list[Complaint]) -> list[dict]:
    codes = active_squad_codes(db, [c.id for c in complaints])
    return [complaint_summary(c, codes.get(c.id)) for c in complaints]


def report_out(r: FieldReport) -> dict:
    return {"id": r.id, "version": r.version, "finding": r.finding, "summary": r.summary,
            "party_or_candidate": r.party_or_candidate, "actions_taken": r.actions_taken or [],
            "seizure": {"made": r.seizure_made,
                        "items": [{"type": i.item_type, "description": i.description, "quantity": i.quantity,
                                   "unit": i.unit, "value_inr": i.value_inr} for i in r.seizure_items]},
            "recommendation": r.recommendation, "submitted_at": r.submitted_at,
            "returned": ({"remarks": r.returned_remarks, "at": r.returned_at} if r.returned_at else None)}


def decision_out(d: Decision) -> dict:
    return {"action": d.action, "final_action": d.final_action, "fir_no": d.fir_no, "reason_code": d.reason_code,
            "escalate_to": d.escalate_to, "remarks": d.remarks, "total_minutes": d.total_minutes,
            "sla_met": d.sla_met, "is_current": d.is_current, "decided_at": d.decided_at}


def escalation_out(e: Escalation) -> dict:
    return {"id": e.id, "level": e.level, "raised_remarks": e.raised_remarks, "action": e.action,
            "final_action": e.final_action, "action_remarks": e.action_remarks,
            "created_at": e.created_at, "closed_at": e.closed_at, "parent_id": e.parent_id}


def assignment_out(a: Assignment) -> dict:
    return {"id": a.uuid, "squad": {"id": a.squad.id, "code": a.squad.code}, "note": a.note,
            "distance_km": a.distance_km, "eta_min": a.eta_min, "assigned_at": a.assigned_at,
            "accepted_at": a.accepted_at, "started_at": a.started_at, "reached_at": a.reached_at,
            "reached_distance_m": a.reached_distance_m, "is_active": a.is_active,
            "ended_reason": a.ended_reason, "reassign_reason": a.reassign_reason}


def stages_out(db: Session, complaint_id: int) -> list[dict]:
    rows = db.scalars(select(ComplaintStageSla).where(ComplaintStageSla.complaint_id == complaint_id)
                      .order_by(ComplaintStageSla.started_at)).all()
    return [{"stage": s.stage, "owner_role": s.owner_role, "started_at": s.started_at, "deadline_at": s.deadline_at,
             "ended_at": s.ended_at, "duration_sec": s.duration_sec,
             "target_min": int((s.deadline_at - s.started_at).total_seconds() // 60),
             "breached": s.breached_at is not None} for s in rows]


def complaint_detail(db: Session, c: Complaint, viewer: User) -> dict:
    out = complaint_summary(c, None)
    out.update({"description": c.description, "language": c.language, "is_anonymous": c.is_anonymous,
                "gps_accuracy_m": c.gps_accuracy_m, "captured_at": c.captured_at, "created_at": c.created_at,
                "sla_deadline": c.sla_deadline,
                "duplicate_of": c.duplicate_of.complaint_no if c.duplicate_of_id and c.duplicate_of else None,
                "dc_drop": {"reason_code": c.dc_drop_reason, "remarks": c.dc_remarks} if c.dc_drop_reason else None})
    # Citizen identity: only DC / DEO / CEO / ADMIN, never for anonymous complaints
    if not c.is_anonymous and viewer.role in ("DC", "DEO", "CEO", "ADMIN"):
        out["citizen"] = {"name": c.citizen.name, "mobile": c.citizen.mobile}
    else:
        out["citizen"] = None
    full = viewer.role in ("DEO", "CEO", "ADMIN")
    media = db.scalars(select(ComplaintMedia).where(ComplaintMedia.complaint_id == c.id)
                       .order_by(ComplaintMedia.captured_at)).all()
    out["media"] = [media_out(m, include_original=full) for m in media]
    asgs = db.scalars(select(Assignment).where(Assignment.complaint_id == c.id).order_by(Assignment.assigned_at)).all()
    out["assignments"] = [assignment_out(a) for a in asgs]
    active = next((a for a in asgs if a.is_active), None)
    out["squad"] = active.squad.code if active else None
    reports = db.scalars(select(FieldReport).where(FieldReport.complaint_id == c.id)
                         .order_by(FieldReport.version.desc())).all()
    out["field_reports"] = [report_out(r) for r in reports]
    out["decisions"] = [decision_out(d) for d in db.scalars(
        select(Decision).where(Decision.complaint_id == c.id).order_by(Decision.decided_at))]
    out["escalations"] = [escalation_out(e) for e in db.scalars(
        select(Escalation).where(Escalation.complaint_id == c.id).order_by(Escalation.created_at))]
    out["timeline"] = [{"from": h.from_status, "to": h.to_status, "actor_role": h.actor_role,
                        "remarks": h.remarks, "at": h.created_at}
                       for h in db.scalars(select(StatusHistory).where(StatusHistory.complaint_id == c.id)
                                           .order_by(StatusHistory.created_at, StatusHistory.id))]
    out["stages"] = stages_out(db, c.id)
    return out


def citizen_view(db: Session, c: Complaint) -> dict:
    """C7: no officer identity, only citizen-visible steps."""
    timeline = []
    for h in db.scalars(select(StatusHistory).where(StatusHistory.complaint_id == c.id)
                        .order_by(StatusHistory.created_at, StatusHistory.id)):
        if h.to_status in CITIZEN_MESSAGES and (not timeline or timeline[-1]["status"] != h.to_status):
            timeline.append({"status": h.to_status, "title": CITIZEN_MESSAGES[h.to_status][0], "at": h.created_at})
    decision = db.scalar(select(Decision).where(Decision.complaint_id == c.id, Decision.is_current.is_(True))
                         .order_by(Decision.decided_at.desc()).limit(1))
    remarks = None
    if c.status in ("DISPOSED", "DROPPED") and decision:
        remarks = decision.remarks
    elif c.status == "RESOLVED":
        esc = db.scalar(select(Escalation).where(Escalation.complaint_id == c.id, Escalation.action == "RESOLVE")
                        .order_by(Escalation.closed_at.desc()).limit(1))
        remarks = esc.action_remarks if esc else None
    elif c.status == "DROPPED_AT_DC":
        remarks = c.dc_remarks
    media = db.scalars(select(ComplaintMedia).where(ComplaintMedia.complaint_id == c.id,
                                                    ComplaintMedia.source == "CITIZEN")).all()
    return {"id": c.uuid, "complaint_no": c.complaint_no, "status": c.status,
            "violation_type": vt_out(c.violation_type), "description": c.description,
            "latitude": c.latitude, "longitude": c.longitude, "is_anonymous": c.is_anonymous,
            "created_at": c.created_at, "submitted_at": c.submitted_at, "closed_at": c.closed_at,
            "timeline": timeline, "remarks": remarks, "media": [media_out(m) for m in media]}
