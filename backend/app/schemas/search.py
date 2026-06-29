"""Global search result schema."""
from __future__ import annotations

import uuid

from pydantic import BaseModel


class SearchHit(BaseModel):
    content_type: str         # article | opportunity | event | publication | resource | faculty
    id: uuid.UUID
    title: str
    subtitle: str | None = None
    image_url: str | None = None


class SearchResults(BaseModel):
    query: str
    total: int
    hits: list[SearchHit]
