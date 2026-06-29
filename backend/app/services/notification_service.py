"""Create notifications and fan out push via FastAPI BackgroundTasks.

Flow:
    Admin/system call  →  create_notification()
        ├── writes Notification row to PostgreSQL (committed before returning)
        └── enqueues _deliver_push() in FastAPI BackgroundTasks
              └── queries DeviceToken rows → send_push() → FCM

A targeted notification (user_id set) pushes only to that user's devices.
A broadcast (user_id None) pushes to every registered device.

Push delivery is always best-effort: FCM errors are logged, never propagated.
Callers that don't have a BackgroundTasks instance (e.g. tests, scripts) may
pass background=None; the push is then skipped and a warning is logged.
"""
from __future__ import annotations

import datetime as dt
import logging
import uuid

from fastapi import BackgroundTasks
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification
from app.models.user import DeviceToken
from app.services.push import send_push

logger = logging.getLogger(__name__)


def _deliver_push(
    tokens: list[str],
    title: str,
    body: str,
    data: dict,
) -> None:
    """Synchronous function executed by FastAPI's background-task worker thread."""
    if not tokens:
        return
    send_push(tokens, title, body, data)


async def create_notification(
    db: AsyncSession,
    *,
    title: str,
    body: str,
    type_: str = "generic",
    user_id: uuid.UUID | None = None,
    data: dict | None = None,
    push: bool = True,
    background: BackgroundTasks | None = None,
) -> Notification:
    """Persist a notification row then optionally enqueue push delivery.

    Args:
        db:         Async database session.
        title:      Notification title (shown in push and in-app).
        body:       Notification body text.
        type_:      One of the NotificationType string values.
        user_id:    Target user; None means broadcast to all users.
        data:       Arbitrary JSON payload forwarded to the FCM data map.
        push:       Set False to skip push (in-app only).
        background: FastAPI BackgroundTasks instance from the request context.
                    If None, push is skipped with a log warning.
    """
    notif = Notification(
        user_id=user_id,
        type=type_,
        title=title,
        body=body,
        data=data or {},
        sent_at=dt.datetime.now(dt.timezone.utc),
    )
    db.add(notif)
    await db.commit()
    await db.refresh(notif)

    if push:
        if background is None:
            logger.warning(
                "create_notification called with push=True but no BackgroundTasks "
                "instance provided — push skipped for notification %s", notif.id
            )
        else:
            # Resolve token list synchronously (we're still in the async context).
            if user_id is not None:
                tokens = list(await db.scalars(
                    select(DeviceToken.fcm_token).where(DeviceToken.user_id == user_id)
                ))
            else:
                tokens = list(await db.scalars(select(DeviceToken.fcm_token)))

            push_data = {"type": type_, **(data or {})}
            background.add_task(_deliver_push, tokens, title, body, push_data)

    return notif
