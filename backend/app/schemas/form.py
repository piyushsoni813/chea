"""Form submission schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict


class FormSubmissionCreate(BaseModel):
    form_type: str
    payload: dict = {}
    attachment_url: str | None = None


class FormSubmissionUpdate(BaseModel):
    status: str | None = None
    admin_note: str | None = None


class FormSubmissionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    form_type: str
    payload: dict
    attachment_url: str | None = None
    status: str
    admin_note: str | None = None
    created_at: dt.datetime
