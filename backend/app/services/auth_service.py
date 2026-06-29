"""Authentication use-cases: register, authenticate, issue/rotate tokens.

Refresh tokens are persisted (by their jti) so they can be rotated on use and
revoked on logout — a stolen-but-used refresh token gets invalidated the moment
the legitimate client refreshes again.
"""
from __future__ import annotations

import datetime as dt

import jwt
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.enums import UserRole
from app.models.user import RefreshToken, StudentProfile, User
from app.schemas.auth import RegisterRequest, TokenPair


def _email_domain_allowed(email: str) -> bool:
    if not settings.ALLOWED_EMAIL_DOMAINS:
        return True
    domain = email.split("@")[-1].lower()
    return domain in {d.lower() for d in settings.ALLOWED_EMAIL_DOMAINS}


async def register_student(db: AsyncSession, data: RegisterRequest) -> User:
    if not _email_domain_allowed(data.email):
        allowed = ", ".join(settings.ALLOWED_EMAIL_DOMAINS)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Registration is restricted to institute emails ({allowed})",
        )
    existing = await db.scalar(select(User).where(User.email == data.email))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail="An account with this email already exists")

    user = User(
        email=str(data.email),
        full_name=data.full_name,
        hashed_password=hash_password(data.password),
        role=UserRole.STUDENT,
        is_verified=False,
    )
    user.student_profile = StudentProfile(
        roll_number=data.roll_number,
        semester=data.semester,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def authenticate(db: AsyncSession, email: str, password: str) -> User:
    user = await db.scalar(select(User).where(User.email == email))
    if not user or not user.hashed_password or not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Incorrect email or password")
    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive account")
    user.last_login_at = dt.datetime.now(dt.timezone.utc)
    await db.commit()
    return user


async def issue_token_pair(db: AsyncSession, user: User) -> TokenPair:
    access = create_access_token(str(user.id), user.role)
    refresh = create_refresh_token(str(user.id))
    payload = decode_token(refresh)
    db.add(RefreshToken(
        user_id=user.id,
        jti=payload["jti"],
        expires_at=dt.datetime.fromtimestamp(payload["exp"], tz=dt.timezone.utc),
    ))
    await db.commit()
    return TokenPair(access_token=access, refresh_token=refresh)


async def rotate_refresh_token(db: AsyncSession, refresh_token: str) -> TokenPair:
    try:
        payload = decode_token(refresh_token)
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Refresh token has expired")
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid refresh token")
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid token type")

    record = await db.scalar(select(RefreshToken).where(RefreshToken.jti == payload["jti"]))
    if not record or record.revoked:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Refresh token is no longer valid")

    user = await db.scalar(select(User).where(User.id == payload["sub"]))
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Account unavailable")

    record.revoked = True  # rotation: old token cannot be reused
    await db.flush()
    return await issue_token_pair(db, user)


async def revoke_all_tokens(db: AsyncSession, user: User) -> None:
    records = (await db.scalars(
        select(RefreshToken).where(RefreshToken.user_id == user.id, RefreshToken.revoked.is_(False))
    )).all()
    for r in records:
        r.revoked = True
    await db.commit()
