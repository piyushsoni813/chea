"""Opportunities: internships, placements, projects, research, scholarships."""
from __future__ import annotations

import datetime as dt

from sqlalchemy import Boolean, DateTime, Integer, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import OpportunityType


class Opportunity(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "opportunities"

    type: Mapped[str] = mapped_column(String(20), index=True,
                                      default=OpportunityType.INTERNSHIP, nullable=False)
    company: Mapped[str] = mapped_column(String(160), index=True, nullable=False)
    role: Mapped[str] = mapped_column(String(160), nullable=False)
    location: Mapped[str | None] = mapped_column(String(160), nullable=True)
    is_remote: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    eligibility: Mapped[str | None] = mapped_column(Text, nullable=True)
    required_skills: Mapped[list[str]] = mapped_column(ARRAY(String), default=list)
    # Free text so we can hold "₹40,000/month", "8-12 LPA", "Negotiable", etc.
    compensation: Mapped[str | None] = mapped_column(String(120), nullable=True)
    company_logo_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    apply_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    deadline: Mapped[dt.datetime | None] = mapped_column(
        DateTime(timezone=True), index=True, nullable=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True, nullable=False)
    applicant_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
