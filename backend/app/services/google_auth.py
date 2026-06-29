"""Verify Google ID tokens and resolve them to a local user.

Uses google-auth to validate the token's signature and audience. New users
authenticating through Google are auto-provisioned as students if their email
domain is allowed.
"""
from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.enums import UserRole
from app.models.user import StudentProfile, User


def _verify_id_token(id_token_str: str) -> dict:
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(status_code=status.HTTP_501_NOT_IMPLEMENTED,
                            detail="Google sign-in is not configured on the server")
    try:
        from google.auth.transport import requests as google_requests
        from google.oauth2 import id_token as google_id_token

        info = google_id_token.verify_oauth2_token(
            id_token_str, google_requests.Request(), settings.GOOGLE_CLIENT_ID,
        )
        return info
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid Google token")


async def login_with_google(db: AsyncSession, id_token_str: str) -> User:
    info = _verify_id_token(id_token_str)
    email = info.get("email")
    sub = info.get("sub")
    if not email or not info.get("email_verified"):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Google account email is not verified")

    user = await db.scalar(select(User).where(User.email == email))
    if user is None:
        domain = email.split("@")[-1].lower()
        if settings.ALLOWED_EMAIL_DOMAINS and domain not in {
            d.lower() for d in settings.ALLOWED_EMAIL_DOMAINS
        }:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN,
                                detail="This Google account is not an institute account")
        user = User(
            email=email,
            full_name=info.get("name", email.split("@")[0]),
            role=UserRole.STUDENT,
            is_verified=True,
            google_sub=sub,
            avatar_url=info.get("picture"),
        )
        user.student_profile = StudentProfile()
        db.add(user)
        await db.commit()
        await db.refresh(user)
    elif user.google_sub is None:
        user.google_sub = sub
        await db.commit()
    return user
