import json
from datetime import date, datetime
from decimal import Decimal
from typing import Any

from fastapi.responses import JSONResponse

from app.core.timeutil import iso


def _default(o: Any):
    if isinstance(o, datetime):
        return iso(o) if o.tzinfo is None else o.isoformat()
    if isinstance(o, date):
        return o.isoformat()
    if isinstance(o, Decimal):
        return float(o)
    if isinstance(o, set):
        return sorted(o)
    raise TypeError(f"not serializable: {type(o)}")


class UTCJSONResponse(JSONResponse):
    """Naive datetimes are UTC in this app: serialize them as ISO 8601 with Z."""

    def render(self, content: Any) -> bytes:
        return json.dumps(content, default=_default, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
