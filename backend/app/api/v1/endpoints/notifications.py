"""Notifications: per-user feed including broadcasts, plus admin send/broadcast."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from sqlalchemy import func, or_, select, update

from app.api.deps import AdminUser, CurrentUser, DbSession, Pagination
from app.models.notification import Notification
from app.schemas.common import Message, Page
from app.schemas.notification import (
    NotificationCreate,
    NotificationRead,
    UnreadCount,
)
from app.services.notification_service import create_notification

router = APIRouter(prefix="/notifications", tags=["notifications"])


def _visible_to_user(user_id: uuid.UUID):
    return or_(Notification.user_id == user_id, Notification.user_id.is_(None))


@router.get("", response_model=Page[NotificationRead])
async def list_notifications(
    user: CurrentUser, db: DbSession, pg: Pagination,
    unread_only: bool = False,
) -> Page[NotificationRead]:
    stmt = select(Notification).where(_visible_to_user(user.id))
    if unread_only:
        stmt = stmt.where(Notification.is_read.is_(False))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Notification.created_at.desc())
        .offset(pg.offset).limit(pg.size)
    )).all()
    return Page.create([NotificationRead.model_validate(r) for r in rows],
                       total or 0, pg.page, pg.size)


@router.get("/unread-count", response_model=UnreadCount)
async def unread_count(user: CurrentUser, db: DbSession) -> UnreadCount:
    count = await db.scalar(
        select(func.count()).select_from(Notification)
        .where(_visible_to_user(user.id), Notification.is_read.is_(False))
    )
    return UnreadCount(unread=count or 0)


@router.post("/{notification_id}/read", response_model=Message)
async def mark_read(
    notification_id: uuid.UUID, user: CurrentUser, db: DbSession,
) -> Message:
    notif = await db.scalar(
        select(Notification).where(
            Notification.id == notification_id, _visible_to_user(user.id)
        )
    )
    if not notif:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Notification not found")
    notif.is_read = True
    await db.commit()
    return Message(detail="Marked as read")


@router.post("/read-all", response_model=Message)
async def mark_all_read(user: CurrentUser, db: DbSession) -> Message:
    await db.execute(
        update(Notification)
        .where(_visible_to_user(user.id), Notification.is_read.is_(False))
        .values(is_read=True)
    )
    await db.commit()
    return Message(detail="All notifications marked as read")


@router.post("/send", response_model=NotificationRead, status_code=201)
async def send_notification(
    data: NotificationCreate,
    user: AdminUser,
    db: DbSession,
    background: BackgroundTasks,          # injected by FastAPI
) -> NotificationRead:
    notif = await create_notification(
        db,
        user_id=data.user_id,
        type_=data.type,
        title=data.title,
        body=data.body,
        data=data.data,
        push=data.push,
        background=background,             # push runs after response is sent
    )
    return NotificationRead.model_validate(notif)
