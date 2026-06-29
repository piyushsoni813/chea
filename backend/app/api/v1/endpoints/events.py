"""Events: list (upcoming/past), detail, QR registration, check-in, CRUD."""
from __future__ import annotations

import datetime as dt
import secrets
import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import selectinload

from app.api.deps import AdminUser, CurrentUser, DbSession, OptionalUser, Pagination, StaffUser
from app.models.event import (
    Event,
    EventGalleryImage,
    EventRegistration,
    EventScheduleItem,
)
from app.schemas.common import Message, Page
from app.schemas.event import (
    CheckInRequest,
    EventCreate,
    EventDetail,
    EventListItem,
    EventUpdate,
    RegistrationRead,
)
from app.utils.slug import unique_slug

router = APIRouter(prefix="/events", tags=["events"])


@router.get("", response_model=Page[EventListItem])
async def list_events(
    db: DbSession,
    pg: Pagination,
    scope: str = Query("upcoming", description="upcoming | past | all"),
    type: str | None = None,
) -> Page[EventListItem]:
    now = dt.datetime.now(dt.timezone.utc)
    stmt = select(Event)
    if scope == "upcoming":
        stmt = stmt.where(Event.starts_at >= now).order_by(Event.starts_at.asc())
    elif scope == "past":
        stmt = stmt.where(Event.starts_at < now).order_by(Event.starts_at.desc())
    else:
        stmt = stmt.order_by(Event.starts_at.desc())
    if type:
        stmt = stmt.where(Event.type == type)

    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(stmt.offset(pg.offset).limit(pg.size))).all()
    return Page.create([EventListItem.model_validate(e) for e in rows],
                       total or 0, pg.page, pg.size)


@router.get("/{slug}", response_model=EventDetail)
async def get_event(slug: str, db: DbSession, user: OptionalUser) -> EventDetail:
    event = await db.scalar(
        select(Event)
        .options(selectinload(Event.schedule), selectinload(Event.gallery))
        .where(Event.slug == slug)
    )
    if not event:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    detail = EventDetail.model_validate(event)
    if user:
        detail.is_registered = bool(await db.scalar(
            select(EventRegistration).where(
                EventRegistration.event_id == event.id,
                EventRegistration.user_id == user.id,
                EventRegistration.status != "cancelled",
            )
        ))
    return detail


@router.post("/{event_id}/register", response_model=RegistrationRead, status_code=201)
async def register_for_event(event_id: uuid.UUID, user: CurrentUser,
                             db: DbSession) -> RegistrationRead:
    event = await db.scalar(select(Event).where(Event.id == event_id))
    if not event:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    if not event.registration_open:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Registration is closed")
    if event.capacity is not None and event.registered_count >= event.capacity:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Event is at full capacity")

    existing = await db.scalar(
        select(EventRegistration).where(
            EventRegistration.event_id == event_id, EventRegistration.user_id == user.id
        )
    )
    if existing:
        if existing.status == "cancelled":
            existing.status = "registered"
            event.registered_count += 1
            await db.commit()
            await db.refresh(existing)
            return RegistrationRead.model_validate(existing)
        raise HTTPException(status.HTTP_409_CONFLICT, "Already registered")

    reg = EventRegistration(
        event_id=event_id, user_id=user.id, qr_token=secrets.token_urlsafe(24),
    )
    event.registered_count += 1
    db.add(reg)
    await db.commit()
    await db.refresh(reg)
    return RegistrationRead.model_validate(reg)


@router.delete("/{event_id}/register", response_model=Message)
async def cancel_registration(event_id: uuid.UUID, user: CurrentUser,
                              db: DbSession) -> Message:
    reg = await db.scalar(
        select(EventRegistration).where(
            EventRegistration.event_id == event_id, EventRegistration.user_id == user.id
        )
    )
    if not reg or reg.status == "cancelled":
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No active registration")
    reg.status = "cancelled"
    event = await db.scalar(select(Event).where(Event.id == event_id))
    if event and event.registered_count > 0:
        event.registered_count -= 1
    await db.commit()
    return Message(detail="Registration cancelled")


@router.post("/{event_id}/check-in", response_model=Message)
async def check_in(event_id: uuid.UUID, data: CheckInRequest,
                   staff: StaffUser, db: DbSession) -> Message:
    reg = await db.scalar(
        select(EventRegistration).where(
            EventRegistration.event_id == event_id,
            EventRegistration.qr_token == data.qr_token,
        )
    )
    if not reg:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Invalid QR code for this event")
    if reg.status == "checked_in":
        return Message(detail="Already checked in")
    reg.status = "checked_in"
    await db.commit()
    return Message(detail="Checked in successfully")


# ----- Admin CRUD -----

@router.post("", response_model=EventDetail, status_code=201)
async def create_event(data: EventCreate, user: AdminUser, db: DbSession) -> EventDetail:
    payload = data.model_dump(exclude={"schedule", "gallery"})
    event = Event(**payload, slug=unique_slug(data.title))
    event.schedule = [EventScheduleItem(**s.model_dump()) for s in data.schedule]
    event.gallery = [EventGalleryImage(**g.model_dump()) for g in data.gallery]
    db.add(event)
    await db.commit()
    loaded = await db.scalar(
        select(Event).options(selectinload(Event.schedule), selectinload(Event.gallery))
        .where(Event.id == event.id)
    )
    return EventDetail.model_validate(loaded)


@router.patch("/{event_id}", response_model=EventDetail)
async def update_event(event_id: uuid.UUID, data: EventUpdate,
                       user: AdminUser, db: DbSession) -> EventDetail:
    event = await db.scalar(select(Event).where(Event.id == event_id))
    if not event:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Event not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(event, field, value)
    await db.commit()
    loaded = await db.scalar(
        select(Event).options(selectinload(Event.schedule), selectinload(Event.gallery))
        .where(Event.id == event.id)
    )
    return EventDetail.model_validate(loaded)


@router.delete("/{event_id}", response_model=Message)
async def delete_event(event_id: uuid.UUID, user: AdminUser, db: DbSession) -> Message:
    await db.execute(delete(Event).where(Event.id == event_id))
    await db.commit()
    return Message(detail="Event deleted")
