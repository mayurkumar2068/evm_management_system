"""Module A: Auth and user (6 APIs)."""
from datetime import timedelta
from typing import Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import RequestMeta, get_current_user, request_meta
from app.core.errors import APIError, rate_limited, unauthorized, validation_error
from app.core.security import (create_access_token, create_refresh_token, generate_otp, hash_otp, new_uuid,
                               sha256_hex, verify_password)
from app.core.timeutil import utcnow
from app.db.session import get_db
from app.models import OtpRequest, RefreshToken, User, UserDevice
from app.services.audit import write_audit

router = APIRouter(prefix="/auth", tags=["A. Auth"])
users_router = APIRouter(tags=["A. Auth"])

MOBILE = r"^[6-9]\d{9}$"


class OtpSendIn(BaseModel):
    mobile: str = Field(pattern=MOBILE, examples=["9876543210"])


class OtpVerifyIn(BaseModel):
    mobile: str | None = Field(default=None, pattern=MOBILE, description="Required for citizen login")
    otp: str = Field(pattern=r"^\d{6}$")
    otp_ref: str
    device_id: str | None = None


class LoginIn(BaseModel):
    username: str
    password: str


class RefreshIn(BaseModel):
    refresh: str
    device_id: str | None = None


class LogoutIn(BaseModel):
    refresh: str
    fcm_token: str | None = None


def _issue_otp(db: Session, mobile: str, purpose: str, meta: RequestMeta) -> dict:
    since = utcnow() - timedelta(minutes=15)
    recent = db.scalar(select(func.count()).select_from(OtpRequest)
                       .where(OtpRequest.mobile == mobile, OtpRequest.created_at >= since))
    if recent >= settings.OTP_MAX_PER_15_MIN:
        raise rate_limited("Too many OTP requests. Try again in 15 minutes")
    ref, otp = new_uuid(), generate_otp()
    db.add(OtpRequest(otp_ref=ref, mobile=mobile, purpose=purpose, otp_hash=hash_otp(ref, otp),
                      expires_at=utcnow() + timedelta(seconds=settings.OTP_TTL_SECONDS), request_ip=meta.ip))
    # TODO production: send `otp` through the SMS gateway (DLT-registered template)
    out = {"otp_ref": ref, "expires_in": settings.OTP_TTL_SECONDS}
    if settings.OTP_DEBUG_RETURN and settings.ENV != "prod":
        out["debug_otp"] = otp
    return out


def _tokens(db: Session, user: User, device_id: str | None) -> dict:
    refresh = create_refresh_token()
    db.add(RefreshToken(user_id=user.id, token_hash=sha256_hex(refresh), device_id=device_id,
                        expires_at=utcnow() + timedelta(days=settings.REFRESH_TOKEN_DAYS)))
    return {"access": create_access_token(user.uuid, user.role), "refresh": refresh,
            "token_type": "Bearer", "expires_in": settings.ACCESS_TOKEN_MINUTES * 60}


def user_out(u: User) -> dict:
    return {"id": u.uuid, "role": u.role, "name": u.name, "mobile": u.mobile, "designation": u.designation,
            "preferred_lang": u.preferred_lang,
            "district": {"code": u.district.code, "name": u.district.name_en} if u.district else None,
            "ac": {"code": u.ac.code, "name": u.ac.name_en} if u.ac else None,
            "squad": {"id": u.squad.id, "code": u.squad.code} if u.squad else None}


PERMISSIONS = {
    "CITIZEN": ["complaint.create", "complaint.view_own"],
    "DC": ["complaint.view_district", "complaint.assign", "complaint.reassign", "complaint.drop",
           "complaint.mark_duplicate", "squad.view", "dashboard.view", "report.view"],
    "FS": ["assignment.view", "assignment.update", "field_report.submit", "location.update"],
    "RO": ["complaint.view_ac", "decision.create", "report.send_back", "dashboard.view"],
    "DEO": ["escalation.view", "escalation.act", "dashboard.view", "report.view", "complaint.view_district"],
    "CEO": ["escalation.view", "escalation.act", "dashboard.view", "report.view", "complaint.view_all"],
    "ADMIN": ["user.manage", "squad.manage", "sla.manage", "dashboard.view", "report.view", "complaint.view_all"],
}


@router.post("/otp/send", summary="A1 Send OTP to a mobile number (citizen login)")
def otp_send(body: OtpSendIn, db: Session = Depends(get_db), meta: RequestMeta = Depends(request_meta)):
    out = _issue_otp(db, body.mobile, "CITIZEN_LOGIN", meta)
    db.commit()
    return out


@router.post("/otp/verify", summary="A2 Verify OTP and get tokens (citizen login or official 2nd step)")
def otp_verify(body: OtpVerifyIn, db: Session = Depends(get_db), meta: RequestMeta = Depends(request_meta)):
    req = db.scalar(select(OtpRequest).where(OtpRequest.otp_ref == body.otp_ref).with_for_update())
    if req is not None and req.purpose == "CITIZEN_LOGIN" and body.mobile != req.mobile:
        req = None
    if req is None or req.verified_at is not None:
        raise unauthorized("Invalid or already used OTP")
    if req.expires_at < utcnow():
        raise unauthorized("OTP expired")
    if req.attempts >= settings.OTP_MAX_ATTEMPTS:
        raise rate_limited("Too many wrong attempts. Request a new OTP")
    if hash_otp(req.otp_ref, body.otp) != req.otp_hash:
        req.attempts += 1
        db.commit()
        raise unauthorized("Wrong OTP")
    req.verified_at = utcnow()

    if req.purpose == "CITIZEN_LOGIN":
        user = db.scalar(select(User).where(User.mobile == req.mobile, User.role == "CITIZEN"))
        if user is None:
            user = User(uuid=new_uuid(), role="CITIZEN", mobile=req.mobile)
            db.add(user)
            db.flush()
    else:  # OFFICIAL_2FA: otp_ref is bound to the official who passed /auth/login
        user = db.scalar(select(User).where(User.mobile == req.mobile, User.role != "CITIZEN",
                                            User.username.is_not(None)).limit(1))
    if user is None or not user.is_active:
        raise unauthorized("User not found or inactive")
    user.last_login_at = utcnow()
    write_audit(db, "user", user.id, "LOGIN", user, meta, {"purpose": req.purpose})
    tokens = _tokens(db, user, body.device_id)
    db.commit()
    return {**tokens, "user": user_out(user)}


@router.post("/login", summary="A3 Official login step 1: username + password, then OTP")
def login(body: LoginIn, db: Session = Depends(get_db), meta: RequestMeta = Depends(request_meta)):
    user = db.scalar(select(User).where(User.username == body.username))
    if user is None or not user.is_active or not verify_password(body.password, user.password_hash):
        raise unauthorized("Wrong username or password")
    out = _issue_otp(db, user.mobile, "OFFICIAL_2FA", meta)
    db.commit()
    return {**out, "mobile_masked": "******" + user.mobile[-4:]}


@router.post("/token/refresh", summary="A4 Get a new access token (refresh token rotates)")
def refresh(body: RefreshIn, db: Session = Depends(get_db)):
    row = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == sha256_hex(body.refresh)).with_for_update())
    if row is None or row.revoked_at is not None or row.expires_at < utcnow():
        raise unauthorized("Invalid or expired refresh token")
    user = db.get(User, row.user_id)
    if user is None or not user.is_active:
        raise unauthorized("User inactive")
    row.revoked_at = utcnow()
    tokens = _tokens(db, user, body.device_id or row.device_id)
    db.commit()
    return tokens


@router.post("/logout", summary="A5 Revoke refresh token and remove device token")
def logout(body: LogoutIn, user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    row = db.scalar(select(RefreshToken).where(RefreshToken.token_hash == sha256_hex(body.refresh),
                                               RefreshToken.user_id == user.id))
    if row and row.revoked_at is None:
        row.revoked_at = utcnow()
    if body.fcm_token:
        dev = db.scalar(select(UserDevice).where(UserDevice.fcm_token == body.fcm_token,
                                                 UserDevice.user_id == user.id))
        if dev:
            dev.is_active = False
    db.commit()
    return {"ok": True}


@users_router.get("/users/me", summary="A6 My profile, role, district, AC and squad")
def me(user: User = Depends(get_current_user)):
    return {**user_out(user), "permissions": PERMISSIONS.get(user.role, [])}


__all__ = ["router", "users_router", "user_out", "APIError", "validation_error", "Literal"]
