"""Resource schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, Field


class ResourceBase(BaseModel):
    title: str = Field(min_length=2, max_length=255)
    type: str = "study_material"
    description: str | None = None
    subject: str | None = None
    semester: int | None = None
    tags: list[str] = []
    file_url: str | None = None
    external_url: str | None = None
    file_size_kb: int | None = None
    is_active: bool = True


class ResourceCreate(ResourceBase):
    pass


class ResourceUpdate(BaseModel):
    title: str | None = None
    type: str | None = None
    description: str | None = None
    subject: str | None = None
    semester: int | None = None
    tags: list[str] | None = None
    file_url: str | None = None
    external_url: str | None = None
    file_size_kb: int | None = None
    is_active: bool | None = None


class ResourceRead(ResourceBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    download_count: int
    created_at: dt.datetime
    is_bookmarked: bool = False
