"""Uploaded-file response schema."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict


class UploadRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    original_name: str
    stored_name: str
    url: str
    content_type: str
    size_bytes: int
    purpose: str | None = None
    created_at: dt.datetime
