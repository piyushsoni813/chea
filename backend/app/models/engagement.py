"""Generic bookmarks and favorites that point at any content type.

Rather than a bookmark table per content type, a single (content_type,
content_id) pair lets a student bookmark an article, a publication, a resource
or an event through one uniform mechanism. Favorites are kept separate from
bookmarks because the product treats them differently (favorites are scoped to
opportunities in the UI, bookmarks to readable content), but the shape is the
same.
"""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin


class Bookmark(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "bookmarks"
    __table_args__ = (
        UniqueConstraint("user_id", "content_type", "content_id", name="uq_bookmark"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    content_type: Mapped[str] = mapped_column(String(30), index=True, nullable=False)
    content_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), index=True, nullable=False)


class Favorite(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "favorites"
    __table_args__ = (
        UniqueConstraint("user_id", "content_type", "content_id", name="uq_favorite"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    content_type: Mapped[str] = mapped_column(String(30), index=True, nullable=False)
    content_id: Mapped[uuid.UUID] = mapped_column(PGUUID(as_uuid=True), index=True, nullable=False)
