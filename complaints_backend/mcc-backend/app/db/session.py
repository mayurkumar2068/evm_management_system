from collections.abc import Iterator

from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
    pool_size=settings.DB_POOL_SIZE,
    pool_recycle=1800,
    echo=settings.DB_ECHO,
    future=True,
)

SessionLocal = sessionmaker(bind=engine, autoflush=True, expire_on_commit=False, class_=Session)


def queue_event(db: Session, event_name: str, data: dict, scope: dict | None = None) -> None:
    """Queue a realtime event; it is published only if the transaction commits."""
    db.info.setdefault("pending_events", []).append((event_name, data, scope or {}))


@event.listens_for(Session, "after_commit")
def _publish_after_commit(session: Session) -> None:
    events = session.info.pop("pending_events", [])
    if not events:
        return
    from app.services.realtime import broadcaster  # local import avoids a cycle

    for name, data, scope in events:
        broadcaster.publish(name, data, scope)


@event.listens_for(Session, "after_rollback")
def _drop_after_rollback(session: Session) -> None:
    session.info.pop("pending_events", None)


def get_db() -> Iterator[Session]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
