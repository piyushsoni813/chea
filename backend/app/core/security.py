"""Password hashing and JWT creation/verification.

Uses bcrypt directly (no passlib) to dodge the well-known passlib/bcrypt
version-skew warnings, and PyJWT for tokens. Access and refresh tokens are
distinguished by a ``type`` claim so a refresh token can never be replayed as
an access token.
"""
from __future__ import annotations

import datetime as dt
import uuid

import bcrypt
import jwt

from app.core.config import settings

ALGORITHM = settings.JWT_ALGORITHM


def hash_password(plain: str) -> str:
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(plain.encode("utf-8"), salt).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False


def _create_token(subject: str, token_type: str, expires_delta: dt.timedelta,
                  extra: dict | None = None) -> str:
    now = dt.datetime.now(dt.timezone.utc)
    payload: dict = {
        "sub": str(subject),
        "type": token_type,
        "iat": now,
        "exp": now + expires_delta,
        "jti": uuid.uuid4().hex,
    }
    if extra:
        payload.update(extra)
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=ALGORITHM)


def create_access_token(subject: str, role: str) -> str:
    return _create_token(
        subject,
        "access",
        dt.timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        extra={"role": role},
    )


def create_refresh_token(subject: str) -> str:
    return _create_token(
        subject,
        "refresh",
        dt.timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def decode_token(token: str) -> dict:
    """Decode and validate signature/expiry. Raises jwt exceptions on failure."""
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
