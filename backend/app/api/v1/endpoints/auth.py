"""Auth endpoints: register, login (JSON + OAuth2 form), refresh, logout, me."""
from __future__ import annotations

from fastapi import APIRouter, Depends, status
from fastapi.security import OAuth2PasswordRequestForm

from app.api.deps import CurrentUser, DbSession
from app.schemas.auth import (
    GoogleLoginRequest,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenPair,
)
from app.schemas.common import Message
from app.schemas.user import UserRead
from app.services import auth_service
from app.services.google_auth import login_with_google

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenPair, status_code=status.HTTP_201_CREATED)
async def register(data: RegisterRequest, db: DbSession) -> TokenPair:
    user = await auth_service.register_student(db, data)
    return await auth_service.issue_token_pair(db, user)


@router.post("/login", response_model=TokenPair)
async def login(data: LoginRequest, db: DbSession) -> TokenPair:
    user = await auth_service.authenticate(db, str(data.email), data.password)
    return await auth_service.issue_token_pair(db, user)


@router.post("/login/oauth", response_model=TokenPair, include_in_schema=False)
async def login_oauth(db: DbSession,
                      form: OAuth2PasswordRequestForm = Depends()) -> TokenPair:
    """Form-encoded login so the Swagger 'Authorize' button works."""
    user = await auth_service.authenticate(db, form.username, form.password)
    return await auth_service.issue_token_pair(db, user)


@router.post("/google", response_model=TokenPair)
async def google_login(data: GoogleLoginRequest, db: DbSession) -> TokenPair:
    user = await login_with_google(db, data.id_token)
    return await auth_service.issue_token_pair(db, user)


@router.post("/refresh", response_model=TokenPair)
async def refresh(data: RefreshRequest, db: DbSession) -> TokenPair:
    return await auth_service.rotate_refresh_token(db, data.refresh_token)


@router.post("/logout", response_model=Message)
async def logout(user: CurrentUser, db: DbSession) -> Message:
    await auth_service.revoke_all_tokens(db, user)
    return Message(detail="Logged out on all devices")


@router.get("/me", response_model=UserRead)
async def me(user: CurrentUser) -> UserRead:
    return UserRead.model_validate(user)
