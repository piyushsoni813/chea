"""Event, schedule, gallery and registration schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, Field


class ScheduleItemIn(BaseModel):
    title: str
    description: str | None = None
    starts_at: dt.datetime


class ScheduleItemRead(ScheduleItemIn):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class GalleryImageIn(BaseModel):
    image_url: str
    caption: str | None = None


class GalleryImageRead(GalleryImageIn):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class EventBase(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    type: str = "workshop"
    description: str
    banner_url: str | None = None
    venue: str | None = None
    starts_at: dt.datetime
    ends_at: dt.datetime | None = None
    registration_open: bool = True
    capacity: int | None = None


class EventCreate(EventBase):
    schedule: list[ScheduleItemIn] = []
    gallery: list[GalleryImageIn] = []


class EventUpdate(BaseModel):
    title: str | None = None
    type: str | None = None
    description: str | None = None
    banner_url: str | None = None
    venue: str | None = None
    starts_at: dt.datetime | None = None
    ends_at: dt.datetime | None = None
    registration_open: bool | None = None
    capacity: int | None = None


class EventListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    title: str
    slug: str
    type: str
    banner_url: str | None = None
    venue: str | None = None
    starts_at: dt.datetime
    ends_at: dt.datetime | None = None
    registration_open: bool
    registered_count: int
    capacity: int | None = None


class EventDetail(EventListItem):
    description: str
    schedule: list[ScheduleItemRead] = []
    gallery: list[GalleryImageRead] = []
    is_registered: bool = False


class RegistrationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    event_id: uuid.UUID
    qr_token: str
    status: str
    created_at: dt.datetime


class CheckInRequest(BaseModel):
    qr_token: str
