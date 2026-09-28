"""All datetimes in the app are timezone-aware UTC.

MySQL DATETIME(3) columns store naive UTC; the UTCDateTime column type converts
on the way in and out, so APIs return ISO 8601 with +00:00.
"""
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy.types import DateTime, TypeDecorator

from app.core.config import settings

IST = ZoneInfo(settings.DISPLAY_TZ)
UTC = timezone.utc


def utcnow() -> datetime:
    now = datetime.now(UTC)
    return now.replace(microsecond=(now.microsecond // 1000) * 1000)   # DATETIME(3) precision


def as_utc(dt: datetime) -> datetime:
    """Treat naive input as UTC; convert aware input to UTC."""
    return dt.replace(tzinfo=UTC) if dt.tzinfo is None else dt.astimezone(UTC)


def iso(dt: datetime | None) -> str | None:
    if dt is None:
        return None
    return as_utc(dt).isoformat(timespec="seconds").replace("+00:00", "Z")


def start_of_today_utc() -> datetime:
    """Midnight in the display timezone (IST), as UTC."""
    local = datetime.now(IST).replace(hour=0, minute=0, second=0, microsecond=0)
    return local.astimezone(UTC)


def minutes_between(a: datetime, b: datetime) -> int:
    return int(round((as_utc(b) - as_utc(a)).total_seconds() / 60))


class UTCDateTime(TypeDecorator):
    impl = DateTime
    cache_ok = True

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return as_utc(value).replace(tzinfo=None)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return value.replace(tzinfo=UTC)


__all__ = ["utcnow", "as_utc", "iso", "start_of_today_utc", "minutes_between", "timedelta", "IST", "UTC",
           "UTCDateTime"]
