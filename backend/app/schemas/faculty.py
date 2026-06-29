"""Faculty directory and contact directory schemas."""
from __future__ import annotations

import uuid

from pydantic import BaseModel, ConfigDict, Field


class FacultyBase(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    designation: str
    email: str | None = None
    phone: str | None = None
    office: str | None = None
    office_hours: str | None = None
    photo_url: str | None = None
    research_interests: list[str] = []
    google_scholar_url: str | None = None
    linkedin_url: str | None = None
    display_order: int = 0


class FacultyCreate(FacultyBase):
    pass


class FacultyUpdate(BaseModel):
    name: str | None = None
    designation: str | None = None
    email: str | None = None
    phone: str | None = None
    office: str | None = None
    office_hours: str | None = None
    photo_url: str | None = None
    research_interests: list[str] | None = None
    google_scholar_url: str | None = None
    linkedin_url: str | None = None
    display_order: int | None = None


class FacultyRead(FacultyBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID


class ContactBase(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    category: str
    role: str | None = None
    email: str | None = None
    phone: str | None = None
    whatsapp: str | None = None
    linkedin_url: str | None = None
    photo_url: str | None = None
    display_order: int = 0


class ContactCreate(ContactBase):
    pass


class ContactUpdate(BaseModel):
    name: str | None = None
    category: str | None = None
    role: str | None = None
    email: str | None = None
    phone: str | None = None
    whatsapp: str | None = None
    linkedin_url: str | None = None
    photo_url: str | None = None
    display_order: int | None = None


class ContactRead(ContactBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
