"""Articles (news + student blogs), their comments and likes.

A single Article model serves both news and blogs, distinguished by ``kind``.
This keeps engagement (likes/comments/bookmarks) uniform instead of duplicating
the machinery across two near-identical tables.
"""
from __future__ import annotations

import datetime as dt
import uuid

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import ARRAY, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import ArticleKind


class Article(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "articles"

    title: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    slug: Mapped[str] = mapped_column(String(280), unique=True, index=True, nullable=False)
    kind: Mapped[str] = mapped_column(String(20), index=True,
                                      default=ArticleKind.NEWS, nullable=False)
    category: Mapped[str] = mapped_column(String(40), index=True, nullable=False)
    excerpt: Mapped[str | None] = mapped_column(String(500), nullable=True)
    body: Mapped[str] = mapped_column(Text, nullable=False)  # markdown / rich text
    cover_image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    reading_minutes: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, index=True, nullable=False)
    view_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    published_at: Mapped[dt.datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    author_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True,
    )
    author: Mapped["object"] = relationship("User", lazy="joined")

    comments: Mapped[list["ArticleComment"]] = relationship(
        back_populates="article", cascade="all, delete-orphan",
    )
    likes: Mapped[list["ArticleLike"]] = relationship(
        back_populates="article", cascade="all, delete-orphan",
    )


class ArticleComment(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "article_comments"

    article_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("articles.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False,
    )
    parent_id: Mapped[uuid.UUID | None] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("article_comments.id", ondelete="CASCADE"),
        nullable=True,
    )
    body: Mapped[str] = mapped_column(String(2000), nullable=False)

    article: Mapped["Article"] = relationship(back_populates="comments")
    user: Mapped["object"] = relationship("User", lazy="joined")


class ArticleLike(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "article_likes"
    __table_args__ = (
        UniqueConstraint("article_id", "user_id", name="uq_article_like"),
    )

    article_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("articles.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False,
    )

    article: Mapped["Article"] = relationship(back_populates="likes")
