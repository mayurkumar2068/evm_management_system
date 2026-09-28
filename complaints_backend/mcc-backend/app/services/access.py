"""Who can see which complaint. Scope is enforced in every query, not only in the UI."""
from sqlalchemy import Select, exists, or_, select
from sqlalchemy.orm import Session

from app.core.errors import forbidden, not_found
from app.models import Assignment, Complaint, User

UUID_LEN = 36


def get_complaint(db: Session, ident: str, for_update: bool = False) -> Complaint:
    q = select(Complaint).where(Complaint.uuid == ident if len(ident) == UUID_LEN else Complaint.complaint_no == ident)
    if for_update:
        q = q.with_for_update()
    c = db.scalar(q)
    if c is None:
        raise not_found("Complaint")
    return c


def squad_has_complaint(db: Session, squad_id: int | None, complaint_id: int) -> bool:
    if not squad_id:
        return False
    return bool(db.scalar(select(exists().where(Assignment.complaint_id == complaint_id,
                                                Assignment.squad_id == squad_id))))


def can_view(db: Session, user: User, c: Complaint) -> bool:
    r = user.role
    if r in ("CEO", "ADMIN"):
        return True
    if r in ("DC", "DEO"):
        return user.district_id is not None and user.district_id == c.district_id
    if r == "RO":
        return user.ac_id is not None and user.ac_id == c.ac_id
    if r == "FS":
        return squad_has_complaint(db, user.squad_id, c.id)
    if r == "CITIZEN":
        return c.citizen_id == user.id
    return False


def assert_can_view(db: Session, user: User, c: Complaint) -> None:
    if not can_view(db, user, c):
        # 404 instead of 403 so IDs outside the caller's scope are not discoverable
        raise not_found("Complaint")


def scope_complaints(q: Select, user: User) -> Select:
    r = user.role
    if r in ("CEO", "ADMIN"):
        return q
    if r in ("DC", "DEO"):
        return q.where(Complaint.district_id == (user.district_id or -1))
    if r == "RO":
        return q.where(Complaint.ac_id == (user.ac_id or -1))
    if r == "FS":
        return q.where(exists().where(Assignment.complaint_id == Complaint.id,
                                      Assignment.squad_id == (user.squad_id or -1)))
    if r == "CITIZEN":
        return q.where(Complaint.citizen_id == user.id)
    raise forbidden()


__all__ = ["get_complaint", "can_view", "assert_can_view", "scope_complaints", "squad_has_complaint", "or_"]
