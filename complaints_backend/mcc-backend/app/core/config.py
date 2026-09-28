from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    APP_NAME: str = "MCC Complaint System"
    ENV: str = "dev"  # dev | test | prod
    API_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str = "mysql+pymysql://root:@127.0.0.1:3306/mcc_complaints?charset=utf8mb4"
    DB_POOL_SIZE: int = 10
    DB_ECHO: bool = False

    # Auth
    JWT_SECRET: str = "change-me-in-production-please-use-64-random-chars"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_MINUTES: int = 15
    REFRESH_TOKEN_DAYS: int = 7
    OTP_TTL_SECONDS: int = 300
    OTP_MAX_ATTEMPTS: int = 5
    OTP_MAX_PER_15_MIN: int = 5
    # In dev/test the OTP is returned in the /auth/otp/send response. Never enable in prod.
    OTP_DEBUG_RETURN: bool = True

    # Business rules
    CITIZEN_MAX_COMPLAINTS_PER_HOUR: int = 10
    CAPTURE_UPLOAD_WINDOW_SECONDS: int = 300      # evidence must be uploaded within 5 min of capture
    MAX_CITIZEN_MEDIA: int = 5
    MAX_PHOTO_BYTES: int = 10 * 1024 * 1024
    MAX_VIDEO_BYTES: int = 25 * 1024 * 1024
    MAX_DOC_BYTES: int = 10 * 1024 * 1024
    DUPLICATE_RADIUS_M: int = 200
    DUPLICATE_WINDOW_MIN: int = 60
    REACHED_GEOFENCE_M: int = 200
    SQUAD_AVG_SPEED_KMPH: float = 20.0
    ACCEPT_WINDOW_MIN: int = 2

    # Storage (local disk in dev; swap for S3/MinIO in prod)
    STORAGE_DIR: str = "storage"
    MEDIA_URL_TTL_SECONDS: int = 600
    PUBLIC_BASE_URL: str = "http://localhost:8000"

    # SLA worker
    ENABLE_SLA_WORKER: bool = False
    SLA_WORKER_INTERVAL_SECONDS: int = 30

    # Push notifications (FCM). Empty = push disabled, in-app notifications still stored.
    FCM_SERVER_KEY: str = ""

    # Display timezone (DB stores UTC)
    DISPLAY_TZ: str = "Asia/Kolkata"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
