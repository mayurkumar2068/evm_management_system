"""Evidence storage.

Dev: local disk under STORAGE_DIR, served by GET /media/{key} with an HMAC-signed,
expiring URL. Prod: implement the same three methods with S3/MinIO
(put_object + generate_presigned_url) and drop the local media route.
"""
import hashlib
import io
import time
from pathlib import Path
from urllib.parse import quote

from app.core.config import settings
from app.core.security import sign_media

IMAGE_MIME = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp", "image/heic": "heic"}
VIDEO_MIME = {"video/mp4": "mp4", "video/quicktime": "mov", "video/3gpp": "3gp"}
AUDIO_MIME = {"audio/mpeg": "mp3", "audio/aac": "aac", "audio/mp4": "m4a"}
DOC_MIME = {"application/pdf": "pdf", **IMAGE_MIME}


class LocalStorage:
    def __init__(self, root: str):
        self.root = Path(root).resolve()
        self.root.mkdir(parents=True, exist_ok=True)

    def _path(self, key: str) -> Path:
        p = (self.root / key).resolve()
        if self.root not in p.parents:
            raise ValueError("invalid key")
        return p

    def save(self, key: str, data: bytes) -> None:
        p = self._path(key)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)

    def read(self, key: str) -> bytes:
        return self._path(key).read_bytes()

    def exists(self, key: str) -> bool:
        try:
            return self._path(key).is_file()
        except ValueError:
            return False

    def signed_url(self, key: str | None) -> str | None:
        if not key:
            return None
        exp = int(time.time()) + settings.MEDIA_URL_TTL_SECONDS
        return f"{settings.PUBLIC_BASE_URL}/media/{quote(key)}?exp={exp}&sig={sign_media(key, exp)}"

    @staticmethod
    def verify(key: str, exp: int, sig: str) -> bool:
        return exp >= int(time.time()) and sign_media(key, exp) == sig


storage = LocalStorage(settings.STORAGE_DIR)


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def strip_exif(data: bytes, mime: str) -> bytes | None:
    """Display copy without EXIF (GPS, device). Original is kept unchanged as evidence."""
    if mime not in ("image/jpeg", "image/png", "image/webp"):
        return None
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(data))
        img.load()
        img.info.clear()  # Pillow writes EXIF only when passed explicitly; clearing info drops it
        out = io.BytesIO()
        img.save(out, format={"image/jpeg": "JPEG", "image/png": "PNG", "image/webp": "WEBP"}[mime], quality=85)
        return out.getvalue()
    except Exception:
        return None
