"""Faculty directory and the broader contact directory."""
from __future__ import annotations

from sqlalchemy import Integer, String
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import ContactCategory


class Faculty(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "faculty"

    name: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    designation: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    office: Mapped[str | None] = mapped_column(String(120), nullable=True)
    office_hours: Mapped[str | None] = mapped_column(String(255), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    research_interests: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    google_scholar_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    linkedin_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)


class Contact(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "contacts"

    name: Mapped[str] = mapped_column(String(120), index=True, nullable=False)
    category: Mapped[str] = mapped_column(String(40), index=True,
                                          default=ContactCategory.FACULTY, nullable=False)
    role: Mapped[str | None] = mapped_column(String(120), nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    whatsapp: Mapped[str | None] = mapped_column(String(20), nullable=True)
    linkedin_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    photo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
