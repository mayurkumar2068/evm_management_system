"""SQLAlchemy ORM models mapped onto the tables created by db/schema.sql.

db/schema.sql is the source of truth for DDL (spatial types, triggers, checks).
ENUM columns are mapped as strings; allowed values are enforced by MySQL and by
the Pydantic schemas / service layer.
"""
from datetime import datetime

from sqlalchemy import (JSON, BigInteger, Computed, DateTime, ForeignKey, Integer, Numeric, SmallInteger,
                        String, Text)
from sqlalchemy.orm import DeclarativeBase, Mapped, deferred, mapped_column, relationship
from sqlalchemy.types import UserDefinedType

from app.core.timeutil import UTCDateTime, utcnow


class Point(UserDefinedType):
    """MySQL POINT SRID 4326. Write with func.ST_SRID(func.POINT(lng, lat), 4326);
    read with ST_Latitude()/ST_Longitude() in queries."""
    cache_ok = True

    def get_col_spec(self, **kw):
        return "POINT SRID 4326"


class Base(DeclarativeBase):
    pass


DT = UTCDateTime()


# ---------------------------------------------------------------- master data
class District(Base):
    __tablename__ = "districts"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(10))
    name_en: Mapped[str] = mapped_column(String(100))
    name_hi: Mapped[str | None] = mapped_column(String(100))
    state_code: Mapped[str] = mapped_column(String(5), default="MP")
    is_active: Mapped[bool] = mapped_column(default=True)


class Constituency(Base):
    __tablename__ = "constituencies"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    district_id: Mapped[int] = mapped_column(ForeignKey("districts.id"))
    ac_no: Mapped[int] = mapped_column(SmallInteger)
    code: Mapped[str] = mapped_column(String(20))
    name_en: Mapped[str] = mapped_column(String(100))
    name_hi: Mapped[str | None] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(default=True)
    district: Mapped[District] = relationship(lazy="joined")


class ViolationType(Base):
    __tablename__ = "violation_types"
    id: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    code: Mapped[str] = mapped_column(String(40))
    name_en: Mapped[str] = mapped_column(String(120))
    name_hi: Mapped[str | None] = mapped_column(String(120))
    sort_order: Mapped[int] = mapped_column(SmallInteger, default=0)
    is_active: Mapped[bool] = mapped_column(default=True)


class SlaConfig(Base):
    __tablename__ = "sla_config"
    stage: Mapped[str] = mapped_column(String(20), primary_key=True)
    target_min: Mapped[int] = mapped_column(SmallInteger)
    warn_pct: Mapped[int] = mapped_column(SmallInteger, default=80)
    escalate_to_role: Mapped[str | None] = mapped_column(String(10))
    updated_by: Mapped[int | None] = mapped_column(BigInteger)
    updated_at: Mapped[datetime] = mapped_column(DT, default=utcnow, onupdate=utcnow)


# ---------------------------------------------------------------- users & auth
class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    uuid: Mapped[str] = mapped_column(String(36))
    role: Mapped[str] = mapped_column(String(10))
    name: Mapped[str | None] = mapped_column(String(150))
    mobile: Mapped[str] = mapped_column(String(15))
    email: Mapped[str | None] = mapped_column(String(150))
    username: Mapped[str | None] = mapped_column(String(60))
    password_hash: Mapped[str | None] = mapped_column(String(255))
    designation: Mapped[str | None] = mapped_column(String(100))
    district_id: Mapped[int | None] = mapped_column(ForeignKey("districts.id"))
    ac_id: Mapped[int | None] = mapped_column(ForeignKey("constituencies.id"))
    squad_id: Mapped[int | None] = mapped_column(ForeignKey("flying_squads.id"))
    preferred_lang: Mapped[str] = mapped_column(String(2), default="hi")
    is_active: Mapped[bool] = mapped_column(default=True)
    last_login_at: Mapped[datetime | None] = mapped_column(DT)
    created_by: Mapped[int | None] = mapped_column(BigInteger)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DT, default=utcnow, onupdate=utcnow)

    district: Mapped[District | None] = relationship(lazy="joined")
    ac: Mapped[Constituency | None] = relationship(lazy="joined")
    squad: Mapped["FlyingSquad | None"] = relationship(foreign_keys=[squad_id], lazy="joined")


class OtpRequest(Base):
    __tablename__ = "otp_requests"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    otp_ref: Mapped[str] = mapped_column(String(36))
    mobile: Mapped[str] = mapped_column(String(15))
    purpose: Mapped[str] = mapped_column(String(20))
    otp_hash: Mapped[str] = mapped_column(String(255))
    attempts: Mapped[int] = mapped_column(SmallInteger, default=0)
    expires_at: Mapped[datetime] = mapped_column(DT)
    verified_at: Mapped[datetime | None] = mapped_column(DT)
    request_ip: Mapped[str | None] = mapped_column(String(45))
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    token_hash: Mapped[str] = mapped_column(String(64))
    device_id: Mapped[str | None] = mapped_column(String(100))
    expires_at: Mapped[datetime] = mapped_column(DT)
    revoked_at: Mapped[datetime | None] = mapped_column(DT)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


class UserDevice(Base):
    __tablename__ = "user_devices"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    platform: Mapped[str] = mapped_column(String(10))
    fcm_token: Mapped[str] = mapped_column(String(255))
    app_version: Mapped[str | None] = mapped_column(String(20))
    is_active: Mapped[bool] = mapped_column(default=True)
    last_seen_at: Mapped[datetime | None] = mapped_column(DT)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


# ---------------------------------------------------------------- squads
class FlyingSquad(Base):
    __tablename__ = "flying_squads"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    code: Mapped[str] = mapped_column(String(20))
    district_id: Mapped[int] = mapped_column(ForeignKey("districts.id"))
    vehicle_no: Mapped[str | None] = mapped_column(String(20))
    leader_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    status: Mapped[str] = mapped_column(String(10), default="OFF_DUTY")
    last_location = deferred(mapped_column(Point))
    last_location_at: Mapped[datetime | None] = mapped_column(DT)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DT, default=utcnow, onupdate=utcnow)


class SquadArea(Base):
    __tablename__ = "squad_areas"
    squad_id: Mapped[int] = mapped_column(ForeignKey("flying_squads.id"), primary_key=True)
    ac_id: Mapped[int] = mapped_column(ForeignKey("constituencies.id"), primary_key=True)


class SquadLocationLog(Base):
    __tablename__ = "squad_location_log"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    squad_id: Mapped[int] = mapped_column(ForeignKey("flying_squads.id"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    location = mapped_column(Point)
    accuracy_m: Mapped[int | None] = mapped_column(SmallInteger)
    recorded_at: Mapped[datetime] = mapped_column(DT)
    received_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


# ---------------------------------------------------------------- complaints
class Complaint(Base):
    __tablename__ = "complaints"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    uuid: Mapped[str] = mapped_column(String(36))
    complaint_no: Mapped[str | None] = mapped_column(String(20))
    citizen_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    is_anonymous: Mapped[bool] = mapped_column(default=False)
    violation_type_id: Mapped[int] = mapped_column(ForeignKey("violation_types.id"))
    description: Mapped[str | None] = mapped_column(Text)
    language: Mapped[str] = mapped_column(String(2), default="hi")
    latitude: Mapped[float] = mapped_column(Numeric(10, 7, asdecimal=False))
    longitude: Mapped[float] = mapped_column(Numeric(10, 7, asdecimal=False))
    location = deferred(mapped_column(Point, Computed("ST_SRID(POINT(longitude, latitude), 4326)", persisted=True)))
    gps_accuracy_m: Mapped[int | None] = mapped_column(SmallInteger)
    address_text: Mapped[str | None] = mapped_column(String(255))
    district_id: Mapped[int | None] = mapped_column(ForeignKey("districts.id"))
    ac_id: Mapped[int | None] = mapped_column(ForeignKey("constituencies.id"))
    status: Mapped[str] = mapped_column(String(20), default="DRAFT")
    current_stage: Mapped[str | None] = mapped_column(String(20))
    stage_deadline: Mapped[datetime | None] = mapped_column(DT)
    sla_deadline: Mapped[datetime | None] = mapped_column(DT)
    is_sla_breached: Mapped[bool] = mapped_column(default=False)
    duplicate_of_id: Mapped[int | None] = mapped_column(ForeignKey("complaints.id"))
    dc_drop_reason: Mapped[str | None] = mapped_column(String(30))
    dc_remarks: Mapped[str | None] = mapped_column(String(500))
    captured_at: Mapped[datetime] = mapped_column(DT)
    upload_deadline: Mapped[datetime] = mapped_column(DT)
    submitted_at: Mapped[datetime | None] = mapped_column(DT)
    closed_at: Mapped[datetime | None] = mapped_column(DT)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DT, default=utcnow, onupdate=utcnow)

    violation_type: Mapped[ViolationType] = relationship(lazy="joined")
    district: Mapped[District | None] = relationship(lazy="joined")
    ac: Mapped[Constituency | None] = relationship(lazy="joined")
    citizen: Mapped[User] = relationship(foreign_keys=[citizen_id], lazy="select")
    duplicate_of: Mapped["Complaint | None"] = relationship(remote_side=[id], lazy="select")


class ComplaintMedia(Base):
    __tablename__ = "complaint_media"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    uuid: Mapped[str] = mapped_column(String(36))
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    uploaded_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    source: Mapped[str] = mapped_column(String(10))
    assignment_id: Mapped[int | None] = mapped_column(ForeignKey("assignments.id"))
    media_type: Mapped[str] = mapped_column(String(10))
    doc_kind: Mapped[str | None] = mapped_column(String(20))
    storage_key: Mapped[str] = mapped_column(String(500))
    display_key: Mapped[str | None] = mapped_column(String(500))
    mime_type: Mapped[str] = mapped_column(String(100))
    size_bytes: Mapped[int] = mapped_column(BigInteger)
    duration_sec: Mapped[int | None] = mapped_column(SmallInteger)
    sha256: Mapped[str] = mapped_column(String(64))
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7, asdecimal=False))
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7, asdecimal=False))
    captured_at: Mapped[datetime] = mapped_column(DT)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


class Assignment(Base):
    __tablename__ = "assignments"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    uuid: Mapped[str] = mapped_column(String(36))
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    squad_id: Mapped[int] = mapped_column(ForeignKey("flying_squads.id"))
    assigned_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    note: Mapped[str | None] = mapped_column(String(500))
    distance_km: Mapped[float | None] = mapped_column(Numeric(6, 2, asdecimal=False))
    eta_min: Mapped[int | None] = mapped_column(SmallInteger)
    assigned_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
    accepted_at: Mapped[datetime | None] = mapped_column(DT)
    started_at: Mapped[datetime | None] = mapped_column(DT)
    reached_at: Mapped[datetime | None] = mapped_column(DT)
    reached_location = deferred(mapped_column(Point))
    reached_distance_m: Mapped[int | None] = mapped_column(SmallInteger)
    is_active: Mapped[bool] = mapped_column(default=True)
    ended_reason: Mapped[str | None] = mapped_column(String(20))
    ended_at: Mapped[datetime | None] = mapped_column(DT)
    reassign_reason: Mapped[str | None] = mapped_column(String(500))

    squad: Mapped[FlyingSquad] = relationship(lazy="joined")
    complaint: Mapped[Complaint] = relationship(lazy="joined")


class FieldReport(Base):
    __tablename__ = "field_reports"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    assignment_id: Mapped[int] = mapped_column(ForeignKey("assignments.id"))
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    submitted_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    version: Mapped[int] = mapped_column(SmallInteger, default=1)
    finding: Mapped[str] = mapped_column(String(30))
    summary: Mapped[str] = mapped_column(Text)
    party_or_candidate: Mapped[str | None] = mapped_column(String(200))
    actions_taken: Mapped[list | None] = mapped_column(JSON)
    seizure_made: Mapped[bool] = mapped_column(default=False)
    recommendation: Mapped[str | None] = mapped_column(String(10))
    returned_by_ro_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    returned_remarks: Mapped[str | None] = mapped_column(String(500))
    returned_at: Mapped[datetime | None] = mapped_column(DT)
    submitted_at: Mapped[datetime] = mapped_column(DT, default=utcnow)

    seizure_items: Mapped[list["SeizureItem"]] = relationship(lazy="selectin", cascade="all, delete-orphan")


class SeizureItem(Base):
    __tablename__ = "seizure_items"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    field_report_id: Mapped[int] = mapped_column(ForeignKey("field_reports.id"))
    item_type: Mapped[str] = mapped_column(String(20))
    description: Mapped[str | None] = mapped_column(String(255))
    quantity: Mapped[float] = mapped_column(Numeric(12, 2, asdecimal=False))
    unit: Mapped[str] = mapped_column(String(20))
    value_inr: Mapped[float | None] = mapped_column(Numeric(14, 2, asdecimal=False))


class Decision(Base):
    __tablename__ = "decisions"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    field_report_id: Mapped[int | None] = mapped_column(ForeignKey("field_reports.id"))
    decided_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    action: Mapped[str] = mapped_column(String(10))
    final_action: Mapped[str | None] = mapped_column(String(30))
    fir_no: Mapped[str | None] = mapped_column(String(50))
    reason_code: Mapped[str | None] = mapped_column(String(20))
    escalate_to: Mapped[str | None] = mapped_column(String(5))
    remarks: Mapped[str] = mapped_column(String(500))
    total_minutes: Mapped[int | None] = mapped_column(SmallInteger)
    sla_met: Mapped[bool | None] = mapped_column()
    is_current: Mapped[bool] = mapped_column(default=True)
    decided_at: Mapped[datetime] = mapped_column(DT, default=utcnow)

    complaint: Mapped[Complaint] = relationship(lazy="joined")


class Escalation(Base):
    __tablename__ = "escalations"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    parent_id: Mapped[int | None] = mapped_column(ForeignKey("escalations.id"))
    level: Mapped[str] = mapped_column(String(5))
    raised_by: Mapped[int] = mapped_column(ForeignKey("users.id"))
    raised_remarks: Mapped[str] = mapped_column(String(500))
    assigned_to: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    action: Mapped[str | None] = mapped_column(String(15))
    final_action: Mapped[str | None] = mapped_column(String(100))
    action_remarks: Mapped[str | None] = mapped_column(String(500))
    action_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
    closed_at: Mapped[datetime | None] = mapped_column(DT)

    complaint: Mapped[Complaint] = relationship(lazy="joined")


# ---------------------------------------------------------------- tracking
class StatusHistory(Base):
    __tablename__ = "status_history"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    from_status: Mapped[str | None] = mapped_column(String(30))
    to_status: Mapped[str] = mapped_column(String(30))
    actor_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    actor_role: Mapped[str] = mapped_column(String(10))
    remarks: Mapped[str | None] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


class ComplaintStageSla(Base):
    __tablename__ = "complaint_stage_sla"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    complaint_id: Mapped[int] = mapped_column(ForeignKey("complaints.id"))
    stage: Mapped[str] = mapped_column(String(20))
    owner_role: Mapped[str] = mapped_column(String(5))
    started_at: Mapped[datetime] = mapped_column(DT)
    deadline_at: Mapped[datetime] = mapped_column(DT)
    ended_at: Mapped[datetime | None] = mapped_column(DT)
    duration_sec: Mapped[int | None] = mapped_column(Integer)
    warned_at: Mapped[datetime | None] = mapped_column(DT)
    breached_at: Mapped[datetime | None] = mapped_column(DT)

    complaint: Mapped[Complaint] = relationship(lazy="joined")


class AuditLog(Base):
    __tablename__ = "audit_log"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    entity: Mapped[str] = mapped_column(String(40))
    entity_id: Mapped[int] = mapped_column(BigInteger)
    action: Mapped[str] = mapped_column(String(60))
    actor_id: Mapped[int | None] = mapped_column(BigInteger)
    actor_role: Mapped[str | None] = mapped_column(String(10))
    ip_address: Mapped[str | None] = mapped_column(String(45))
    user_agent: Mapped[str | None] = mapped_column(String(255))
    payload: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)


class Notification(Base):
    __tablename__ = "notifications"
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    complaint_id: Mapped[int | None] = mapped_column(ForeignKey("complaints.id"))
    type: Mapped[str] = mapped_column(String(40))
    title: Mapped[str] = mapped_column(String(150))
    body: Mapped[str] = mapped_column(String(500))
    data: Mapped[dict | None] = mapped_column(JSON)
    push_status: Mapped[str] = mapped_column(String(10), default="PENDING")
    read_at: Mapped[datetime | None] = mapped_column(DT)
    created_at: Mapped[datetime] = mapped_column(DT, default=utcnow)
