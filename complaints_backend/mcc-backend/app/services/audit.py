from sqlalchemy.orm import Session

from app.core.deps import RequestMeta
from app.models import AuditLog, User


def write_audit(db: Session, entity: str, entity_id: int, action: str, actor: User | None = None,
                meta: RequestMeta | None = None, payload: dict | None = None) -> None:
    db.add(AuditLog(
        entity=entity, entity_id=entity_id, action=action,
        actor_id=actor.id if actor else None,
        actor_role=actor.role if actor else "SYSTEM",
        ip_address=meta.ip if meta else None,
        user_agent=meta.user_agent if meta else None,
        payload=payload,
    ))
