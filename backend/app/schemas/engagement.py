"""Bookmark and favorite schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict


class ToggleRequest(BaseModel):
    content_type: str
    content_id: uuid.UUID


class ToggleResponse(BaseModel):
    active: bool


class EngagementRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    content_type: str
    content_id: uuid.UUID
    created_at: dt.datetime
