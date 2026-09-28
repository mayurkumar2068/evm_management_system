"""WebSocket broadcaster (API N4).

Events are queued on the DB session and published only after commit
(see app/db/session.py). This in-process broadcaster works for a single
API instance. For several instances behind a load balancer, replace
`publish` with Redis pub/sub and keep `_deliver` as the subscriber.
"""
import asyncio
import json
import logging
import threading
from dataclasses import dataclass, field

from fastapi import WebSocket

from app.core.timeutil import iso, utcnow

log = logging.getLogger("realtime")


@dataclass(eq=False)
class Connection:
    ws: WebSocket
    user_id: int
    role: str
    district_id: int | None
    ac_id: int | None
    squad_id: int | None
    queue: asyncio.Queue = field(default_factory=lambda: asyncio.Queue(maxsize=500))


def can_receive(conn: Connection, scope: dict) -> bool:
    roles = scope.get("roles")
    if roles and conn.role not in roles:
        return False
    user_ids = scope.get("user_ids") or []
    if conn.user_id in user_ids:
        return True
    if scope.get("only_users"):
        return False
    if conn.role in ("CEO", "ADMIN"):
        return True
    if conn.role in ("DC", "DEO"):
        return conn.district_id is not None and conn.district_id == scope.get("district_id")
    if conn.role == "RO":
        return conn.ac_id is not None and conn.ac_id == scope.get("ac_id")
    if conn.role == "FS":
        return conn.squad_id is not None and conn.squad_id == scope.get("squad_id")
    return False


class Broadcaster:
    def __init__(self) -> None:
        self.loop: asyncio.AbstractEventLoop | None = None
        self.connections: set[Connection] = set()
        self._lock = threading.Lock()

    def attach_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        self.loop = loop

    def add(self, conn: Connection) -> None:
        with self._lock:
            self.connections.add(conn)

    def remove(self, conn: Connection) -> None:
        with self._lock:
            self.connections.discard(conn)

    def publish(self, event: str, data: dict, scope: dict) -> None:
        """Thread-safe. Called after DB commit from sync request handlers or the SLA worker."""
        message = json.dumps({"event": event, "data": data, "at": iso(utcnow())}, default=str)
        loop = self.loop
        if loop is None or loop.is_closed():
            return
        try:
            running = asyncio.get_running_loop()
        except RuntimeError:
            running = None
        if running is loop:
            self._deliver(message, scope)
        else:
            loop.call_soon_threadsafe(self._deliver, message, scope)

    def _deliver(self, message: str, scope: dict) -> None:
        with self._lock:
            targets = [c for c in self.connections if can_receive(c, scope)]
        for conn in targets:
            try:
                conn.queue.put_nowait(message)
            except asyncio.QueueFull:
                log.warning("dropping event for slow websocket user=%s", conn.user_id)


broadcaster = Broadcaster()
