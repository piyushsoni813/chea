"""Form submissions: students submit and track; staff review and resolve."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, BackgroundTasks, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession, Pagination, StaffUser
from app.models.form import FormSubmission
from app.schemas.common import Page
from app.schemas.form import (
    FormSubmissionCreate,
    FormSubmissionRead,
    FormSubmissionUpdate,
)
from app.services.notification_service import create_notification

router = APIRouter(prefix="/forms", tags=["forms"])


@router.post("/submit", response_model=FormSubmissionRead, status_code=201)
async def submit_form(
    data: FormSubmissionCreate, user: CurrentUser, db: DbSession,
) -> FormSubmissionRead:
    submission = FormSubmission(
        user_id=user.id,
        form_type=data.form_type,
        payload=data.payload,
        attachment_url=data.attachment_url,
    )
    db.add(submission)
    await db.commit()
    await db.refresh(submission)
    return FormSubmissionRead.model_validate(submission)


@router.get("/mine", response_model=Page[FormSubmissionRead])
async def my_submissions(
    user: CurrentUser, db: DbSession, pg: Pagination,
    form_type: str | None = None,
) -> Page[FormSubmissionRead]:
    stmt = select(FormSubmission).where(FormSubmission.user_id == user.id)
    if form_type:
        stmt = stmt.where(FormSubmission.form_type == form_type)
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(FormSubmission.created_at.desc())
        .offset(pg.offset).limit(pg.size)
    )).all()
    return Page.create([FormSubmissionRead.model_validate(r) for r in rows],
                       total or 0, pg.page, pg.size)


# ── staff review ──────────────────────────────────────────────────────────────

@router.get("", response_model=Page[FormSubmissionRead])
async def list_submissions(
    user: StaffUser, db: DbSession, pg: Pagination,
    form_type: str | None = None, submission_status: str | None = None,
) -> Page[FormSubmissionRead]:
    stmt = select(FormSubmission)
    if form_type:
        stmt = stmt.where(FormSubmission.form_type == form_type)
    if submission_status:
        stmt = stmt.where(FormSubmission.status == submission_status)
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(FormSubmission.created_at.desc())
        .offset(pg.offset).limit(pg.size)
    )).all()
    return Page.create([FormSubmissionRead.model_validate(r) for r in rows],
                       total or 0, pg.page, pg.size)


@router.patch("/{submission_id}", response_model=FormSubmissionRead)
async def review_submission(
    submission_id: uuid.UUID,
    data: FormSubmissionUpdate,
    user: StaffUser,
    db: DbSession,
    background: BackgroundTasks,           # push runs after response is sent
) -> FormSubmissionRead:
    submission = await db.scalar(
        select(FormSubmission)
        .options(selectinload(FormSubmission.user))
        .where(FormSubmission.id == submission_id)
    )
    if not submission:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Submission not found")

    changed_status = data.status and data.status != submission.status
    for f, v in data.model_dump(exclude_unset=True).items():
        setattr(submission, f, v)
    await db.commit()
    await db.refresh(submission)

    if changed_status:
        await create_notification(
            db,
            user_id=submission.user_id,
            type_="generic",
            title="Update on your submission",
            body=(f"Your {submission.form_type.replace('_', ' ')} is now "
                  f"{submission.status}."),
            data={"form_submission_id": str(submission.id)},
            background=background,
        )
    return FormSubmissionRead.model_validate(submission)
