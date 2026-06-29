"""Events plus their gallery, schedule and registrations."""
from __future__ import annotations

import datetime as dt
import uuid

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import EventType, RegistrationStatus


class Event(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "events"

    title: Mapped[str] = mapped_column(String(200), index=True, nullable=False)
    slug: Mapped[str] = mapped_column(String(220), unique=True, index=True, nullable=False)
    type: Mapped[str] = mapped_column(String(30), index=True,
                                      default=EventType.WORKSHOP, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    banner_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    venue: Mapped[str | None] = mapped_column(String(200), nullable=True)
    starts_at: Mapped[dt.datetime] = mapped_column(DateTime(timezone=True), index=True, nullable=False)
    ends_at: Mapped[dt.datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    registration_open: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    capacity: Mapped[int | None] = mapped_column(Integer, nullable=True)
    registered_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    gallery: Mapped[list["EventGalleryImage"]] = relationship(
        back_populates="event", cascade="all, delete-orphan",
    )
    schedule: Mapped[list["EventScheduleItem"]] = relationship(
        back_populates="event", cascade="all, delete-orphan",
        order_by="EventScheduleItem.starts_at",
    )
    registrations: Mapped[list["EventRegistration"]] = relationship(
        back_populates="event", cascade="all, delete-orphan",
    )


class EventGalleryImage(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "event_gallery_images"

    event_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("events.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    image_url: Mapped[str] = mapped_column(String(512), nullable=False)
    caption: Mapped[str | None] = mapped_column(String(255), nullable=True)

    event: Mapped["Event"] = relationship(back_populates="gallery")


class EventScheduleItem(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "event_schedule_items"

    event_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("events.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    starts_at: Mapped[dt.datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    event: Mapped["Event"] = relationship(back_populates="schedule")


class EventRegistration(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "event_registrations"
    __table_args__ = (
        UniqueConstraint("event_id", "user_id", name="uq_event_registration"),
    )

    event_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("events.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    # Opaque token encoded into the QR shown at the door.
    qr_token: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    status: Mapped[str] = mapped_column(String(20), default=RegistrationStatus.REGISTERED, nullable=False)

    event: Mapped["Event"] = relationship(back_populates="registrations")
    user: Mapped["object"] = relationship("User", lazy="joined")
