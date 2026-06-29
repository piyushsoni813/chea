"""The signed-in student's own profile, devices and saved collections."""
from __future__ import annotations

import uuid

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession
from app.models.engagement import Bookmark, Favorite
from app.models.event import Event, EventRegistration
from app.models.user import DeviceToken, StudentProfile, User
from app.schemas.auth import DeviceRegisterRequest
from app.schemas.common import Message
from app.schemas.event import EventListItem
from app.schemas.user import StudentProfileUpdate, UserRead, UserUpdate

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserRead)
async def get_my_profile(user: CurrentUser) -> UserRead:
    return UserRead.model_validate(user)


@router.patch("", response_model=UserRead)
async def update_my_account(data: UserUpdate, user: CurrentUser, db: DbSession) -> UserRead:
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    await db.commit()
    await db.refresh(user)
    return UserRead.model_validate(user)


@router.patch("/student", response_model=UserRead)
async def update_student_profile(data: StudentProfileUpdate, user: CurrentUser,
                                 db: DbSession) -> UserRead:
    profile = user.student_profile
    if profile is None:
        profile = StudentProfile(user_id=user.id)
        db.add(profile)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)
    await db.commit()
    refreshed = await db.scalar(
        select(User).options(selectinload(User.student_profile)).where(User.id == user.id)
    )
    return UserRead.model_validate(refreshed)


@router.put("/resume", response_model=Message)
async def set_resume(url: str, user: CurrentUser, db: DbSession) -> Message:
    profile = user.student_profile or StudentProfile(user_id=user.id)
    profile.resume_url = url
    db.add(profile)
    await db.commit()
    return Message(detail="Resume updated")


@router.post("/devices", response_model=Message, status_code=201)
async def register_device(data: DeviceRegisterRequest, user: CurrentUser,
                          db: DbSession) -> Message:
    existing = await db.scalar(
        select(DeviceToken).where(DeviceToken.fcm_token == data.fcm_token)
    )
    if existing:
        existing.user_id = user.id
        existing.platform = data.platform
    else:
        db.add(DeviceToken(user_id=user.id, fcm_token=data.fcm_token, platform=data.platform))
    await db.commit()
    return Message(detail="Device registered for push notifications")


@router.delete("/devices/{fcm_token}", response_model=Message)
async def unregister_device(fcm_token: str, user: CurrentUser, db: DbSession) -> Message:
    token = await db.scalar(
        select(DeviceToken).where(
            DeviceToken.fcm_token == fcm_token, DeviceToken.user_id == user.id
        )
    )
    if token:
        await db.delete(token)
        await db.commit()
    return Message(detail="Device unregistered")


@router.get("/registrations", response_model=list[EventListItem])
async def my_registered_events(user: CurrentUser, db: DbSession) -> list[EventListItem]:
    rows = await db.execute(
        select(Event)
        .join(EventRegistration, EventRegistration.event_id == Event.id)
        .where(EventRegistration.user_id == user.id,
               EventRegistration.status != "cancelled")
        .order_by(Event.starts_at.desc())
    )
    return [EventListItem.model_validate(e) for e in rows.scalars().all()]
