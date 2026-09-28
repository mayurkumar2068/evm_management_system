"""Module M: Admin and master data (9 APIs)."""
from typing import Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy import or_, select, update
from sqlalchemy.orm import Session

from app.core.deps import RequestMeta, get_current_user, request_meta, require_roles
from app.core.errors import APIError, not_found, validation_error
from app.core.security import hash_password, new_uuid
from app.db.session import get_db
from app.models import Constituency, District, FlyingSquad, SlaConfig, SquadArea, User
from app.routers.auth import user_out
from app.services import geo, sla
from app.services.audit import write_audit
from app.services.serializers import paginate

router = APIRouter(tags=["M. Admin & masters"])
admin_only = require_roles("ADMIN")

OfficialRole = Literal["DC", "FS", "RO", "DEO", "CEO", "ADMIN"]
MOBILE = r"^[6-9]\d{9}$"


class UserCreateIn(BaseModel):
    role: OfficialRole
    name: str = Field(min_length=2, max_length=150)
    mobile: str = Field(pattern=MOBILE)
    username: str = Field(min_length=3, max_length=60, pattern=r"^[a-zA-Z0-9_.-]+$")
    password: str = Field(min_length=8, max_length=128)
    email: str | None = Field(default=None, max_length=150)
    designation: str | None = Field(default=None, max_length=100)
    district_code: str | None = None
    ac_code: str | None = None
    squad_id: int | None = None
    preferred_lang: Literal["hi", "en"] = "en"


class UserUpdateIn(BaseModel):
    role: OfficialRole | None = None
    name: str | None = Field(default=None, min_length=2, max_length=150)
    mobile: str | None = Field(default=None, pattern=MOBILE)
    email: str | None = None
    designation: str | None = None
    district_code: str | None = None
    ac_code: str | None = None
    squad_id: int | None = None
    clear_squad: bool = False
    is_active: bool | None = None
    password: str | None = Field(default=None, min_length=8, max_length=128)


class SquadCreateIn(BaseModel):
    code: str = Field(min_length=2, max_length=20, examples=["FS-02"])
    district_code: str
    vehicle_no: str | None = Field(default=None, max_length=20)
    leader_user_id: str | None = Field(default=None, description="User UUID of the magistrate in charge")
    member_user_ids: list[str] = Field(default=[], description="User UUIDs (role FS)")
    area_ac_codes: list[str] = []


class SquadUpdateIn(BaseModel):
    vehicle_no: str | None = None
    leader_user_id: str | None = None
    member_user_ids: list[str] | None = None
    area_ac_codes: list[str] | None = None
    is_active: bool | None = None
    status: Literal["AVAILABLE", "BUSY", "OFF_DUTY"] | None = None


class SlaItemIn(BaseModel):
    stage: Literal["ALLOCATION", "TRAVEL", "ENQUIRY", "RO_DECISION"]
    target_min: int = Field(ge=1, le=600)
    warn_pct: int = Field(default=80, ge=1, le=100)
    escalate_to_role: Literal["DC", "DEO", "CEO"] | None = None


class SlaConfigIn(BaseModel):
    stages: list[SlaItemIn] = Field(min_length=1, max_length=4)


def _district(db: Session, code: str | None) -> District | None:
    if code is None:
        return None
    d = db.scalar(select(District).where(District.code == code))
    if d is None:
        raise validation_error(f"Unknown district {code}")
    return d


def _ac(db: Session, code: str | None) -> Constituency | None:
    if code is None:
        return None
    a = db.scalar(select(Constituency).where(Constituency.code == code))
    if a is None:
        raise validation_error(f"Unknown AC {code}")
    return a


def _validate_posting(db: Session, u: User) -> None:
    if u.role in ("DC", "FS", "RO", "DEO") and not u.district_id:
        raise validation_error(f"district_code is required for role {u.role}")
    if u.role == "RO" and not u.ac_id:
        raise validation_error("ac_code is required for role RO")
    if u.ac_id:
        ac = db.get(Constituency, u.ac_id)
        if ac.district_id != u.district_id:
            raise validation_error("AC does not belong to the district")
    if u.role == "FS":
        if not u.squad_id:
            raise validation_error("squad_id is required for role FS")
        sq = db.get(FlyingSquad, u.squad_id)
        if sq is None or sq.district_id != u.district_id:
            raise validation_error("Squad not found in this district")
    elif u.squad_id:
        raise validation_error("Only FS users can belong to a squad")
    dup = db.scalar(select(User.id).where(User.mobile == u.mobile, User.role != "CITIZEN", User.id != (u.id or 0)))
    if dup:
        raise APIError(409, "CONFLICT", "Another official already uses this mobile number")


def _users_by_uuid(db: Session, uuids: list[str]) -> list[User]:
    users = db.scalars(select(User).where(User.uuid.in_(uuids or ["-"]))).all()
    missing = set(uuids) - {u.uuid for u in users}
    if missing:
        raise validation_error("Unknown users", missing=sorted(missing))
    return list(users)


def squad_out(db: Session, s: FlyingSquad) -> dict:
    members = db.scalars(select(User).where(User.squad_id == s.id)).all()
    areas = db.scalars(select(Constituency.code).join(SquadArea, SquadArea.ac_id == Constituency.id)
                       .where(SquadArea.squad_id == s.id)).all()
    lat, lng = geo.squad_lat_lng(db, s.id)
    leader = db.get(User, s.leader_user_id) if s.leader_user_id else None
    return {"id": s.id, "code": s.code, "district_id": s.district_id, "vehicle_no": s.vehicle_no,
            "status": s.status, "is_active": s.is_active,
            "leader": {"id": leader.uuid, "name": leader.name} if leader else None,
            "members": [{"id": m.uuid, "name": m.name, "mobile": m.mobile, "is_active": m.is_active} for m in members],
            "area_ac_codes": list(areas),
            "last_location": {"latitude": lat, "longitude": lng} if lat is not None else None,
            "last_location_at": s.last_location_at}


def _set_members_areas(db: Session, s: FlyingSquad, member_ids: list[str] | None, ac_codes: list[str] | None):
    if member_ids is not None:
        members = _users_by_uuid(db, member_ids)
        bad = [m.uuid for m in members if m.role != "FS" or m.district_id != s.district_id]
        if bad:
            raise validation_error("Members must be FS users of the same district", users=bad)
        db.execute(update(User).where(User.squad_id == s.id).values(squad_id=None))
        for m in members:
            m.squad_id = s.id
    if ac_codes is not None:
        acs = [_ac(db, code) for code in ac_codes]
        if any(a.district_id != s.district_id for a in acs):
            raise validation_error("All ACs must be in the squad's district")
        db.query(SquadArea).filter(SquadArea.squad_id == s.id).delete()
        for a in acs:
            db.add(SquadArea(squad_id=s.id, ac_id=a.id))


@router.get("/admin/users", summary="M1 List officials")
def list_users(role: OfficialRole | None = None, district: str | None = None, q: str | None = None,
               is_active: bool | None = None, page: int = Query(1, ge=1), page_size: int = Query(20, ge=1, le=100),
               _: User = Depends(admin_only), db: Session = Depends(get_db)):
    query = select(User).where(User.role != "CITIZEN")
    if role:
        query = query.where(User.role == role)
    if district:
        query = query.where(User.district_id == _district(db, district).id)
    if is_active is not None:
        query = query.where(User.is_active.is_(is_active))
    if q:
        query = query.where(or_(User.name.like(f"%{q}%"), User.username.like(f"%{q}%"), User.mobile.like(f"%{q}%")))
    return paginate(db, query.order_by(User.role, User.name), page, page_size,
                    lambda u: {**user_out(u), "username": u.username, "is_active": u.is_active,
                               "last_login_at": u.last_login_at})


@router.post("/admin/users", status_code=201, summary="M2 Create an official (DC, FS, RO, DEO, CEO, ADMIN)")
def create_user(body: UserCreateIn, admin: User = Depends(admin_only), db: Session = Depends(get_db),
                meta: RequestMeta = Depends(request_meta)):
    if db.scalar(select(User.id).where(User.username == body.username)):
        raise APIError(409, "CONFLICT", "Username already exists")
    d, a = _district(db, body.district_code), _ac(db, body.ac_code)
    u = User(uuid=new_uuid(), role=body.role, name=body.name, mobile=body.mobile, email=body.email,
             username=body.username, password_hash=hash_password(body.password), designation=body.designation,
             district_id=d.id if d else None, ac_id=a.id if a else None, squad_id=body.squad_id,
             preferred_lang=body.preferred_lang, created_by=admin.id)
    _validate_posting(db, u)
    db.add(u)
    db.flush()
    write_audit(db, "user", u.id, "CREATE", admin, meta, {"role": u.role, "username": u.username})
    db.commit()
    return {**user_out(u), "username": u.username, "is_active": u.is_active}


@router.patch("/admin/users/{user_id}", summary="M3 Update role / posting, reset password or deactivate")
def update_user(user_id: str, body: UserUpdateIn, admin: User = Depends(admin_only), db: Session = Depends(get_db),
                meta: RequestMeta = Depends(request_meta)):
    u = db.scalar(select(User).where(User.uuid == user_id, User.role != "CITIZEN"))
    if u is None:
        raise not_found("User")
    data = body.model_dump(exclude_unset=True)
    for f in ("role", "name", "mobile", "email", "designation", "is_active"):
        if f in data:
            setattr(u, f, data[f])
    if "district_code" in data:
        u.district_id = _district(db, body.district_code).id if body.district_code else None
    if "ac_code" in data:
        u.ac_id = _ac(db, body.ac_code).id if body.ac_code else None
    if "squad_id" in data:
        u.squad_id = body.squad_id
    if body.clear_squad:
        u.squad_id = None
    if body.password:
        u.password_hash = hash_password(body.password)
    _validate_posting(db, u)
    changes = {k: v for k, v in data.items() if k != "password"}
    write_audit(db, "user", u.id, "UPDATE", admin, meta, {**changes, "password_reset": bool(body.password)})
    db.commit()
    return {**user_out(u), "username": u.username, "is_active": u.is_active}


@router.get("/admin/squads", summary="M4 List flying squads")
def list_squads(district: str | None = None, _: User = Depends(admin_only), db: Session = Depends(get_db)):
    q = select(FlyingSquad)
    if district:
        q = q.where(FlyingSquad.district_id == _district(db, district).id)
    return {"results": [squad_out(db, s) for s in db.scalars(q.order_by(FlyingSquad.district_id, FlyingSquad.code))]}


@router.post("/admin/squads", status_code=201, summary="M5 Create a squad with members, vehicle and area")
def create_squad(body: SquadCreateIn, admin: User = Depends(admin_only), db: Session = Depends(get_db),
                 meta: RequestMeta = Depends(request_meta)):
    d = _district(db, body.district_code)
    if db.scalar(select(FlyingSquad.id).where(FlyingSquad.district_id == d.id, FlyingSquad.code == body.code)):
        raise APIError(409, "CONFLICT", f"Squad {body.code} already exists in {d.code}")
    s = FlyingSquad(code=body.code, district_id=d.id, vehicle_no=body.vehicle_no, status="OFF_DUTY")
    db.add(s)
    db.flush()
    _set_members_areas(db, s, body.member_user_ids, body.area_ac_codes)
    if body.leader_user_id:
        s.leader_user_id = _users_by_uuid(db, [body.leader_user_id])[0].id
    write_audit(db, "squad", s.id, "CREATE", admin, meta, body.model_dump())
    db.commit()
    return squad_out(db, s)


@router.patch("/admin/squads/{squad_id}", summary="M6 Change members, area, vehicle or active flag")
def update_squad(squad_id: int, body: SquadUpdateIn, admin: User = Depends(admin_only), db: Session = Depends(get_db),
                 meta: RequestMeta = Depends(request_meta)):
    s = db.get(FlyingSquad, squad_id)
    if s is None:
        raise not_found("Squad")
    data = body.model_dump(exclude_unset=True)
    for f in ("vehicle_no", "is_active", "status"):
        if f in data:
            setattr(s, f, data[f])
    if "leader_user_id" in data:
        s.leader_user_id = _users_by_uuid(db, [body.leader_user_id])[0].id if body.leader_user_id else None
    _set_members_areas(db, s, body.member_user_ids, body.area_ac_codes)
    write_audit(db, "squad", s.id, "UPDATE", admin, meta, data)
    db.commit()
    return squad_out(db, s)


@router.get("/masters/districts", summary="M7 Districts (optionally with GeoJSON boundary)")
def districts(include_boundary: bool = False, _: User = Depends(get_current_user), db: Session = Depends(get_db)):
    rows = db.scalars(select(District).where(District.is_active.is_(True)).order_by(District.name_en)).all()
    return {"results": [{"id": d.id, "code": d.code, "name_en": d.name_en, "name_hi": d.name_hi,
                         "state_code": d.state_code,
                         **({"boundary": geo.boundary_geojson(db, "districts", d.id)} if include_boundary else {})}
                        for d in rows]}


@router.get("/masters/constituencies", summary="M8 Assembly constituencies with mapped RO")
def constituencies(district: str | None = None, include_boundary: bool = False,
                   _: User = Depends(get_current_user), db: Session = Depends(get_db)):
    q = select(Constituency).where(Constituency.is_active.is_(True))
    if district:
        q = q.where(Constituency.district_id == _district(db, district).id)
    rows = db.scalars(q.order_by(Constituency.ac_no)).all()
    ros = {u.ac_id: u for u in db.scalars(select(User).where(User.role == "RO", User.is_active.is_(True),
                                                              User.ac_id.in_([a.id for a in rows] or [-1])))}
    return {"results": [{"id": a.id, "code": a.code, "ac_no": a.ac_no, "name_en": a.name_en, "name_hi": a.name_hi,
                         "district": a.district.code,
                         "ro": {"name": ros[a.id].name, "designation": ros[a.id].designation} if a.id in ros else None,
                         **({"boundary": geo.boundary_geojson(db, "constituencies", a.id)} if include_boundary else {})}
                        for a in rows]}


@router.put("/admin/sla-config", summary="M9 Set stage targets (5 / 15 / 30 / 50 min) and alert thresholds")
def put_sla(body: SlaConfigIn, admin: User = Depends(admin_only), db: Session = Depends(get_db),
            meta: RequestMeta = Depends(request_meta)):
    for item in body.stages:
        row = db.get(SlaConfig, item.stage)
        if row is None:
            row = SlaConfig(stage=item.stage)
            db.add(row)
        row.target_min, row.warn_pct = item.target_min, item.warn_pct
        row.escalate_to_role, row.updated_by = item.escalate_to_role, admin.id
    write_audit(db, "sla_config", 0, "UPDATE", admin, meta, body.model_dump())
    db.commit()
    cfg = sla.load_config(db)
    return {"stages": [{"stage": s, "target_min": cfg[s].target_min, "warn_pct": cfg[s].warn_pct,
                        "escalate_to_role": cfg[s].escalate_to_role} for s in sla.STAGES],
            "total_min": sum(cfg[s].target_min for s in sla.STAGES),
            "note": "New targets apply to stages that start after this change"}
