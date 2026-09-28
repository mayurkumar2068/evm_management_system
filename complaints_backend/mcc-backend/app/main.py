import asyncio
import logging
from contextlib import asynccontextmanager
from pathlib import PurePosixPath

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse

from app.core.config import settings
from app.core.errors import APIError, register_error_handlers
from app.core.responses import UTCJSONResponse
from app.routers import admin, auth, citizen, dashboard, dc, escalation, fs, notifications, ro
from app.services.realtime import broadcaster
from app.services.storage import LocalStorage, storage

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")


@asynccontextmanager
async def lifespan(app: FastAPI):
    broadcaster.attach_loop(asyncio.get_running_loop())
    sched = None
    if settings.ENABLE_SLA_WORKER:
        from app.workers.sla_worker import start_background
        sched = start_background()
    yield
    if sched:
        sched.shutdown(wait=False)


app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="MCC violation complaint system: Citizen → District Controller → Flying Squad → "
                "Returning Officer → DEO/CEO. 100-minute SLA.",
    default_response_class=UTCJSONResponse,
    lifespan=lifespan,
)
app.add_middleware(CORSMiddleware, allow_origins=["*"] if settings.ENV != "prod" else [],
                   allow_methods=["*"], allow_headers=["*"])
register_error_handlers(app)

P = settings.API_PREFIX
app.include_router(auth.router, prefix=P)
app.include_router(auth.users_router, prefix=P)
app.include_router(citizen.router, prefix=P)
app.include_router(dc.router, prefix=P)
app.include_router(fs.router, prefix=P)
app.include_router(ro.router, prefix=P)
app.include_router(escalation.router, prefix=P)
app.include_router(dashboard.router, prefix=P)
app.include_router(admin.router, prefix=P)
app.include_router(notifications.router, prefix=P)


@app.get("/health", include_in_schema=False)
def health():
    return {"status": "ok"}


@app.get("/media/{key:path}", include_in_schema=False)
def media(key: str, exp: int = Query(...), sig: str = Query(...)):
    """Serves locally stored evidence through signed, expiring URLs (dev only; use S3 presigned URLs in prod)."""
    if ".." in PurePosixPath(key).parts or not LocalStorage.verify(key, exp, sig) or not storage.exists(key):
        raise APIError(403, "FORBIDDEN", "Link expired or invalid")
    return FileResponse(storage._path(key))
