"""Publication schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, Field


class PublicationBase(BaseModel):
    title: str = Field(min_length=2, max_length=255)
    type: str = "magazine"
    academic_year: str
    description: str | None = None
    cover_image_url: str | None = None
    pdf_url: str
    is_published: bool = True


class PublicationCreate(PublicationBase):
    pass


class PublicationUpdate(BaseModel):
    title: str | None = None
    type: str | None = None
    academic_year: str | None = None
    description: str | None = None
    cover_image_url: str | None = None
    pdf_url: str | None = None
    is_published: bool | None = None


class PublicationRead(PublicationBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    download_count: int
    published_at: dt.datetime | None = None
    created_at: dt.datetime
    is_bookmarked: bool = False
