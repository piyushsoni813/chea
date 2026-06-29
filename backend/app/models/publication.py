"""Department publications: magazine, gazette, papers, reports, newsletters."""
from __future__ import annotations

import datetime as dt

from sqlalchemy import Boolean, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import PublicationType


class Publication(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "publications"

    title: Mapped[str] = mapped_column(String(255), index=True, nullable=False)
    type: Mapped[str] = mapped_column(String(30), index=True,
                                      default=PublicationType.MAGAZINE, nullable=False)
    academic_year: Mapped[str] = mapped_column(String(12), index=True, nullable=False)  # e.g. 2024-25
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    cover_image_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    pdf_url: Mapped[str] = mapped_column(String(512), nullable=False)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
    download_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    published_at: Mapped[dt.datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
