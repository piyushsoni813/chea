"""Opportunity schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, Field


class OpportunityBase(BaseModel):
    type: str = "internship"
    company: str = Field(min_length=1, max_length=160)
    role: str = Field(min_length=1, max_length=160)
    location: str | None = None
    is_remote: bool = False
    description: str
    eligibility: str | None = None
    required_skills: list[str] = []
    compensation: str | None = None
    company_logo_url: str | None = None
    apply_url: str | None = None
    deadline: dt.datetime | None = None
    is_active: bool = True


class OpportunityCreate(OpportunityBase):
    pass


class OpportunityUpdate(BaseModel):
    type: str | None = None
    company: str | None = None
    role: str | None = None
    location: str | None = None
    is_remote: bool | None = None
    description: str | None = None
    eligibility: str | None = None
    required_skills: list[str] | None = None
    compensation: str | None = None
    company_logo_url: str | None = None
    apply_url: str | None = None
    deadline: dt.datetime | None = None
    is_active: bool | None = None


class OpportunityRead(OpportunityBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    applicant_count: int
    created_at: dt.datetime
    is_favorited: bool = False
    is_bookmarked: bool = False
