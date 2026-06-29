"""Application settings, loaded from environment variables.

Everything configurable lives here so that the rest of the codebase never
reads os.environ directly. Twelve-factor style: config comes from the
environment, with sane local defaults so a fresh clone boots without a long
setup ritual.
"""
from functools import lru_cache
from typing import Any

from pydantic import AnyHttpUrl, EmailStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # --- Core ---
    PROJECT_NAME: str = "CHEA API"
    API_V1_PREFIX: str = "/api/v1"
    ENVIRONMENT: str = "development"  # development | staging | production
    DEBUG: bool = True
    SECRET_KEY: str = "change-me-in-production-use-a-long-random-string"

    # --- Auth / JWT ---
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    JWT_ALGORITHM: str = "HS256"
    # Only addresses on these domains may self-register as students/faculty.
    ALLOWED_EMAIL_DOMAINS: list[str] = ["chea.edu", "students.chea.edu"]

    # --- Database ---
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_USER: str = "chea"
    POSTGRES_PASSWORD: str = "chea"
    POSTGRES_DB: str = "chea"
    DB_ECHO: bool = False


    # --- CORS ---
    BACKEND_CORS_ORIGINS: list[str] = ["*"]

    # --- Uploads ---
    UPLOAD_DIR: str = "uploads"
    MAX_UPLOAD_MB: int = 25
    ALLOWED_UPLOAD_EXTENSIONS: list[str] = [
        ".pdf", ".png", ".jpg", ".jpeg", ".webp", ".doc", ".docx",
    ]

    # --- Email (SMTP) ---
    SMTP_HOST: str | None = None
    SMTP_PORT: int = 587
    SMTP_USER: str | None = None
    SMTP_PASSWORD: str | None = None
    SMTP_FROM: EmailStr = "noreply@chea.edu"
    SMTP_TLS: bool = True

    # --- Google Sign-In ---
    GOOGLE_CLIENT_ID: str | None = None

    # --- Firebase Cloud Messaging (push) ---
    FCM_CREDENTIALS_PATH: str | None = None  # path to service-account JSON

    # --- First superuser, seeded on startup ---
    FIRST_SUPERUSER_EMAIL: EmailStr = "admin@chea.edu"
    FIRST_SUPERUSER_PASSWORD: str = "admin12345"

    @field_validator("BACKEND_CORS_ORIGINS", "ALLOWED_EMAIL_DOMAINS",
                     "ALLOWED_UPLOAD_EXTENSIONS", mode="before")
    @classmethod
    def _split_csv(cls, v: Any) -> Any:
        if isinstance(v, str) and not v.startswith("["):
            return [item.strip() for item in v.split(",") if item.strip()]
        return v

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def sync_database_url(self) -> str:
        # Alembic / tooling that prefers a sync driver.
        return (
            f"postgresql+psycopg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )



@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
