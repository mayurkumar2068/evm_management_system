from collections.abc import Callable

import jwt
from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.errors import forbidden, unauthorized
from app.core.security import decode_access_token
from app.db.session import get_db
from app.models import User

bearer = HTTPBearer(auto_error=False)

OFFICIAL_ROLES = ("DC", "FS", "RO", "DEO", "CEO", "ADMIN")


def user_from_token(db: Session, token: str) -> User:
    try:
        payload = decode_access_token(token)
    except jwt.ExpiredSignatureError:
        raise unauthorized("Access token expired")
    except jwt.PyJWTError:
        raise unauthorized("Invalid access token")
    user = db.scalar(select(User).where(User.uuid == payload["sub"]))
    if not user or not user.is_active:
        raise unauthorized("User not found or inactive")
    return user


def get_current_user(creds: HTTPAuthorizationCredentials | None = Depends(bearer),
                     db: Session = Depends(get_db)) -> User:
    if creds is None or creds.scheme.lower() != "bearer":
        raise unauthorized()
    return user_from_token(db, creds.credentials)


def require_roles(*roles: str) -> Callable[..., User]:
    def checker(user: User = Depends(get_current_user)) -> User:
        if user.role not in roles:
            raise forbidden(f"This API is for roles: {', '.join(roles)}")
        return user
    return checker


class RequestMeta:
    def __init__(self, ip: str | None, user_agent: str | None):
        self.ip = ip
        self.user_agent = user_agent


def request_meta(request: Request) -> RequestMeta:
    fwd = request.headers.get("x-forwarded-for")
    ip = fwd.split(",")[0].strip() if fwd else (request.client.host if request.client else None)
    return RequestMeta(ip, (request.headers.get("user-agent") or "")[:255] or None)
