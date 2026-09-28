import hashlib
import hmac
import secrets
import uuid
from datetime import timedelta

import bcrypt
import jwt

from app.core.config import settings
from app.core.timeutil import utcnow


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12)).decode()


def verify_password(password: str, password_hash: str | None) -> bool:
    if not password_hash:
        return False
    try:
        return bcrypt.checkpw(password.encode(), password_hash.encode())
    except ValueError:
        return False


def generate_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"


def hash_otp(otp_ref: str, otp: str) -> str:
    """HMAC so a leaked DB row cannot be brute-forced offline without the secret."""
    return hmac.new(settings.JWT_SECRET.encode(), f"{otp_ref}:{otp}".encode(), hashlib.sha256).hexdigest()


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode()).hexdigest()


def new_uuid() -> str:
    return str(uuid.uuid4())


def create_access_token(user_uuid: str, role: str) -> str:
    now = utcnow()
    payload = {"sub": user_uuid, "role": role, "type": "access",
               "iat": now, "exp": now + timedelta(minutes=settings.ACCESS_TOKEN_MINUTES),
               "jti": secrets.token_hex(8)}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token() -> str:
    return secrets.token_urlsafe(48)


def decode_access_token(token: str) -> dict:
    """Raises jwt.PyJWTError when invalid or expired."""
    payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    if payload.get("type") != "access":
        raise jwt.InvalidTokenError("not an access token")
    return payload


def sign_media(key: str, expires_ts: int) -> str:
    return hmac.new(settings.JWT_SECRET.encode(), f"media:{key}:{expires_ts}".encode(), hashlib.sha256).hexdigest()[:32]
