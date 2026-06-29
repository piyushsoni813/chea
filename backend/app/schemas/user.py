"""User and student-profile schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class StudentProfileRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    roll_number: str | None = None
    semester: int | None = None
    branch: str
    phone: str | None = None
    bio: str | None = None
    resume_url: str | None = None
    linkedin_url: str | None = None
    github_url: str | None = None


class StudentProfileUpdate(BaseModel):
    roll_number: str | None = None
    semester: int | None = Field(default=None, ge=1, le=10)
    phone: str | None = Field(default=None, max_length=20)
    bio: str | None = Field(default=None, max_length=500)
    linkedin_url: str | None = None
    github_url: str | None = None


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    role: str
    is_active: bool
    is_verified: bool
    avatar_url: str | None = None
    created_at: dt.datetime
    student_profile: StudentProfileRead | None = None


class UserUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=120)
    avatar_url: str | None = None


class UserAdminUpdate(BaseModel):
    role: str | None = None
    is_active: bool | None = None
    is_verified: bool | None = None
