"""Admin surface: dashboard analytics, user management, role assignment.

User listing and edits sit behind the admin guard; changing a role is further
narrowed to super admins so a regular admin cannot mint other admins."""
from __future__ import annotations

import datetime as dt
import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.api.deps import AdminUser, DbSession, Pagination, SuperAdminUser
from app.models.content import Article
from app.models.enums import SubmissionStatus, UserRole
from app.models.event import Event
from app.models.faculty import Faculty
from app.models.form import FormSubmission
from app.models.notification import Notification
from app.models.opportunity import Opportunity
from app.models.publication import Publication
from app.models.resource import Resource
from app.models.user import User
from app.schemas.admin import DashboardStats
from app.schemas.common import Page
from app.schemas.user import UserAdminUpdate, UserRead

router = APIRouter(prefix="/admin", tags=["admin"])


async def _count(db: DbSession, model, *conditions) -> int:
    stmt = select(func.count()).select_from(model)
    for c in conditions:
        stmt = stmt.where(c)
    return (await db.scalar(stmt)) or 0


@router.get("/stats", response_model=DashboardStats)
async def dashboard_stats(user: AdminUser, db: DbSession) -> DashboardStats:
    now = dt.datetime.now(dt.timezone.utc)
    return DashboardStats(
        total_users=await _count(db, User),
        total_students=await _count(db, User, User.role == UserRole.STUDENT),
        total_faculty=await _count(db, Faculty),
        total_articles=await _count(db, Article),
        total_opportunities=await _count(db, Opportunity),
        active_opportunities=await _count(db, Opportunity, Opportunity.is_active.is_(True)),
        total_events=await _count(db, Event),
        upcoming_events=await _count(db, Event, Event.starts_at >= now),
        total_publications=await _count(db, Publication),
        total_resources=await _count(db, Resource),
        pending_forms=await _count(db, FormSubmission,
                                   FormSubmission.status == SubmissionStatus.PENDING),
        notifications_sent=await _count(db, Notification, Notification.sent_at.is_not(None)),
    )


@router.get("/users", response_model=Page[UserRead])
async def list_users(
    user: AdminUser, db: DbSession, pg: Pagination,
    role: str | None = None, q: str | None = None, is_active: bool | None = None,
) -> Page[UserRead]:
    stmt = select(User).options(selectinload(User.student_profile))
    if role:
        stmt = stmt.where(User.role == role)
    if is_active is not None:
        stmt = stmt.where(User.is_active.is_(is_active))
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(User.full_name.ilike(like), User.email.ilike(like)))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(User.created_at.desc()).offset(pg.offset).limit(pg.size)
    )).all()
    items = [UserRead.model_validate(u) for u in rows]
    return Page.create(items, total or 0, pg.page, pg.size)


@router.patch("/users/{user_id}", response_model=UserRead)
async def update_user(
    user_id: uuid.UUID, data: UserAdminUpdate,
    actor: AdminUser, db: DbSession,
) -> UserRead:
    target = await db.scalar(
        select(User).options(selectinload(User.student_profile))
        .where(User.id == user_id)
    )
    if not target:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    payload = data.model_dump(exclude_unset=True)
    # Only super admins may change roles.
    if "role" in payload and actor.role != UserRole.SUPER_ADMIN:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only a super admin can change roles"
        )
    for f, v in payload.items():
        setattr(target, f, v)
    await db.commit()
    await db.refresh(target)
    return UserRead.model_validate(target)


@router.post("/users/{user_id}/promote", response_model=UserRead)
async def promote_user(
    user_id: uuid.UUID, role: str,
    actor: SuperAdminUser, db: DbSession,
) -> UserRead:
    if role not in {r.value for r in UserRole}:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Unknown role")
    target = await db.scalar(
        select(User).options(selectinload(User.student_profile))
        .where(User.id == user_id)
    )
    if not target:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    target.role = role
    await db.commit()
    await db.refresh(target)
    return UserRead.model_validate(target)
