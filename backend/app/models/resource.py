"""Study resources, notes, papers, books, software, useful links, repos."""
from __future__ import annotations

from sqlalchemy import Boolean, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import ResourceType


class Resource(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "resources"

    title: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    type: Mapped[str] = mapped_column(String(30), index=True,
                                      default=ResourceType.STUDY_MATERIAL, nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    subject: Mapped[str | None] = mapped_column(String(120), index=True, nullable=True)
    semester: Mapped[int | None] = mapped_column(Integer, index=True, nullable=True)
    tags: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    # Exactly one of these is expected depending on type (file vs external link).
    file_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    external_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    file_size_kb: Mapped[int | None] = mapped_column(Integer, nullable=True)
    download_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
