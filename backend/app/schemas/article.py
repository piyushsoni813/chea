"""Article (news + blog), comment, and like schemas."""
from __future__ import annotations

import datetime as dt
import uuid

from pydantic import BaseModel, ConfigDict, Field


class AuthorMini(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    full_name: str
    avatar_url: str | None = None


class ArticleBase(BaseModel):
    title: str = Field(min_length=3, max_length=255)
    kind: str = "news"
    category: str
    excerpt: str | None = None
    body: str
    cover_image_url: str | None = None
    tags: list[str] = []
    is_published: bool = True
    is_featured: bool = False


class ArticleCreate(ArticleBase):
    pass


class ArticleUpdate(BaseModel):
    title: str | None = None
    kind: str | None = None
    category: str | None = None
    excerpt: str | None = None
    body: str | None = None
    cover_image_url: str | None = None
    tags: list[str] | None = None
    is_published: bool | None = None
    is_featured: bool | None = None


class ArticleListItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    title: str
    slug: str
    kind: str
    category: str
    excerpt: str | None = None
    cover_image_url: str | None = None
    tags: list[str]
    reading_minutes: int
    is_featured: bool
    view_count: int
    published_at: dt.datetime | None = None
    author: AuthorMini | None = None
    like_count: int = 0
    comment_count: int = 0


class ArticleDetail(ArticleListItem):
    body: str
    is_published: bool
    is_bookmarked: bool = False
    is_liked: bool = False


class CommentCreate(BaseModel):
    body: str = Field(min_length=1, max_length=2000)
    parent_id: uuid.UUID | None = None


class CommentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    body: str
    parent_id: uuid.UUID | None = None
    created_at: dt.datetime
    user: AuthorMini
