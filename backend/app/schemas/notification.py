"""Notification schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict


class NotificationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    type: str
    title: str
    body: str
    data: dict
    is_read: bool
    created_at: dt.datetime


class NotificationCreate(BaseModel):
    # user_id None => broadcast to everyone
    user_id: uuid.UUID | None = None
    type: str = "generic"
    title: str
    body: str
    data: dict = {}
    push: bool = True


class UnreadCount(BaseModel):
    unread: int
