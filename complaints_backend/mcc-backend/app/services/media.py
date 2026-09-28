from datetime import datetime, timedelta

from fastapi import UploadFile
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.errors import APIError, validation_error
from app.core.security import new_uuid
from app.core.timeutil import as_utc, utcnow
from app.models import ComplaintMedia, Complaint, User
from app.services.storage import AUDIO_MIME, DOC_MIME, IMAGE_MIME, VIDEO_MIME, sha256_bytes, storage, strip_exif

LIMITS = {"PHOTO": (IMAGE_MIME, settings.MAX_PHOTO_BYTES), "VIDEO": (VIDEO_MIME, settings.MAX_VIDEO_BYTES),
          "AUDIO": (AUDIO_MIME, settings.MAX_VIDEO_BYTES), "DOCUMENT": (DOC_MIME, settings.MAX_DOC_BYTES)}


def save_media(db: Session, *, complaint: Complaint, user: User, source: str, file: UploadFile, media_type: str,
               captured_at: datetime, sha256: str | None, latitude: float | None, longitude: float | None,
               duration_sec: int | None = None, doc_kind: str | None = None,
               assignment_id: int | None = None, enforce_fresh: bool = False) -> ComplaintMedia:
    media_type = media_type.upper()
    if media_type not in LIMITS:
        raise validation_error("media_type must be PHOTO, VIDEO, AUDIO or DOCUMENT")
    allowed, max_bytes = LIMITS[media_type]
    mime = (file.content_type or "").lower()
    if mime not in allowed:
        raise validation_error(f"File type {mime or 'unknown'} not allowed for {media_type}",
                               allowed=sorted(allowed))
    data = file.file.read(max_bytes + 1)
    if len(data) > max_bytes:
        raise APIError(413, "PAYLOAD_TOO_LARGE", f"{media_type} larger than {max_bytes // (1024 * 1024)} MB")
    if not data:
        raise validation_error("Empty file")
    digest = sha256_bytes(data)
    if sha256 and sha256.lower() != digest:
        raise validation_error("sha256 does not match the uploaded file", expected=sha256, actual=digest)

    captured = as_utc(captured_at)
    now = utcnow()
    if captured > now + timedelta(minutes=2):
        raise validation_error("captured_at is in the future")
    if enforce_fresh and now - captured > timedelta(seconds=settings.CAPTURE_UPLOAD_WINDOW_SECONDS):
        raise validation_error("Evidence must be uploaded within 5 minutes of capture (live capture only)")

    if source == "CITIZEN":
        count = db.scalar(select(func.count()).select_from(ComplaintMedia).where(
            ComplaintMedia.complaint_id == complaint.id, ComplaintMedia.source == "CITIZEN"))
        if count >= settings.MAX_CITIZEN_MEDIA:
            raise validation_error(f"Maximum {settings.MAX_CITIZEN_MEDIA} files per complaint")

    uid = new_uuid()
    ext = allowed[mime]
    key = f"{complaint.uuid}/{source.lower()}/{uid}.{ext}"
    storage.save(key, data)
    display_key = None
    clean = strip_exif(data, mime)
    if clean is not None:
        display_key = f"{complaint.uuid}/{source.lower()}/{uid}.display.{ext}"
        storage.save(display_key, clean)

    m = ComplaintMedia(uuid=uid, complaint_id=complaint.id, uploaded_by=user.id, source=source,
                       assignment_id=assignment_id, media_type=media_type, doc_kind=doc_kind,
                       storage_key=key, display_key=display_key, mime_type=mime, size_bytes=len(data),
                       duration_sec=duration_sec, sha256=digest, latitude=latitude, longitude=longitude,
                       captured_at=captured)
    db.add(m)
    db.flush()
    return m


def media_out(m: ComplaintMedia, include_original: bool = False) -> dict:
    out = {"id": m.uuid, "source": m.source, "media_type": m.media_type, "doc_kind": m.doc_kind,
           "mime_type": m.mime_type, "size_bytes": m.size_bytes, "sha256": m.sha256,
           "captured_at": m.captured_at, "latitude": m.latitude, "longitude": m.longitude,
           "url": storage.signed_url(m.display_key or m.storage_key)}
    if include_original:
        out["original_url"] = storage.signed_url(m.storage_key)
    return out
