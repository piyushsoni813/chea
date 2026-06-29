"""CHEA backend application entrypoint.

Wires together configuration, logging, CORS, the versioned API, static file
serving for uploads, and a small set of friendly exception handlers. On startup
it ensures the first super admin exists so a freshly migrated database is
immediately usable.
"""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.api.v1 import api_router
from app.core.config import settings
from app.core.logging import configure_logging
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.enums import UserRole
from app.models.user import User

configure_logging()
logger = logging.getLogger("chea")


async def ensure_first_superuser() -> None:
    """Create the bootstrap super admin if no account with that email exists."""
    async with AsyncSessionLocal() as db:
        existing = await db.scalar(
            select(User).where(User.email == settings.FIRST_SUPERUSER_EMAIL)
        )
        if existing:
            return
        db.add(User(
            email=settings.FIRST_SUPERUSER_EMAIL,
            full_name="CHEA Administrator",
            hashed_password=hash_password(settings.FIRST_SUPERUSER_PASSWORD),
            role=UserRole.SUPER_ADMIN,
            is_active=True,
            is_verified=True,
        ))
        try:
            await db.commit()
            logger.info("Seeded first super admin: %s", settings.FIRST_SUPERUSER_EMAIL)
        except IntegrityError:
            await db.rollback()  # created concurrently by another worker


@asynccontextmanager
async def lifespan(app: FastAPI):
    Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
    try:
        await ensure_first_superuser()
    except Exception:  # never let seeding crash boot; log and continue
        logger.exception("Could not seed first super admin")
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Official backend for the Chemical Engineering Students Association app.",
    openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(RequestValidationError)
async def validation_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": "Validation failed", "errors": exc.errors()},
    )


@app.exception_handler(IntegrityError)
async def integrity_handler(request: Request, exc: IntegrityError):
    logger.warning("Integrity error on %s: %s", request.url.path, exc)
    return JSONResponse(
        status_code=status.HTTP_409_CONFLICT,
        content={"detail": "That operation conflicts with existing data."},
    )


@app.get("/", tags=["meta"])
async def root() -> dict[str, str]:
    return {"name": settings.PROJECT_NAME, "status": "ok", "docs": "/docs"}


@app.get("/health", tags=["meta"])
async def health() -> dict[str, str]:
    return {"status": "healthy"}


# Serve uploaded files (dev/simple deployments; behind NGINX in production).
_upload_path = Path(settings.UPLOAD_DIR)
_upload_path.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(_upload_path)), name="static")

app.include_router(api_router, prefix=settings.API_V1_PREFIX)
