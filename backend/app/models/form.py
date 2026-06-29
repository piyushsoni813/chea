"""Form submissions of every supported type, with review workflow."""
from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin, UUIDMixin
from app.models.enums import SubmissionStatus


class FormSubmission(UUIDMixin, TimestampMixin, Base):
    __tablename__ = "form_submissions"

    user_id: Mapped[uuid.UUID] = mapped_column(
        PGUUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"),
        index=True, nullable=False,
    )
    form_type: Mapped[str] = mapped_column(String(40), index=True, nullable=False)
    # Free-form per-form fields kept in JSONB so new form shapes need no migration.
    payload: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    attachment_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    status: Mapped[str] = mapped_column(String(20), default=SubmissionStatus.PENDING,
                                        index=True, nullable=False)
    admin_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    user: Mapped["object"] = relationship("User", lazy="joined")
