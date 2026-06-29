"""Faculty directory: public browse/search, staff-managed CRUD."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete, func, or_, select

from app.api.deps import AdminUser, DbSession, Pagination
from app.models.faculty import Faculty
from app.schemas.common import Message, Page
from app.schemas.faculty import FacultyCreate, FacultyRead, FacultyUpdate

router = APIRouter(prefix="/faculty", tags=["faculty"])


@router.get("", response_model=Page[FacultyRead])
async def list_faculty(
    db: DbSession, pg: Pagination, q: str | None = None,
) -> Page[FacultyRead]:
    stmt = select(Faculty)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(
            Faculty.name.ilike(like),
            Faculty.designation.ilike(like),
            Faculty.email.ilike(like),
        ))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Faculty.display_order, Faculty.name)
        .offset(pg.offset).limit(pg.size)
    )).all()
    items = [FacultyRead.model_validate(r) for r in rows]
    return Page.create(items, total or 0, pg.page, pg.size)


@router.get("/{faculty_id}", response_model=FacultyRead)
async def get_faculty(faculty_id: uuid.UUID, db: DbSession) -> FacultyRead:
    member = await db.scalar(select(Faculty).where(Faculty.id == faculty_id))
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Faculty member not found")
    return FacultyRead.model_validate(member)


@router.post("", response_model=FacultyRead, status_code=201)
async def create_faculty(data: FacultyCreate, user: AdminUser, db: DbSession) -> FacultyRead:
    member = Faculty(**data.model_dump())
    db.add(member)
    await db.commit()
    await db.refresh(member)
    return FacultyRead.model_validate(member)


@router.patch("/{faculty_id}", response_model=FacultyRead)
async def update_faculty(faculty_id: uuid.UUID, data: FacultyUpdate,
                         user: AdminUser, db: DbSession) -> FacultyRead:
    member = await db.scalar(select(Faculty).where(Faculty.id == faculty_id))
    if not member:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Faculty member not found")
    for f, v in data.model_dump(exclude_unset=True).items():
        setattr(member, f, v)
    await db.commit()
    await db.refresh(member)
    return FacultyRead.model_validate(member)


@router.delete("/{faculty_id}", response_model=Message)
async def delete_faculty(faculty_id: uuid.UUID, user: AdminUser, db: DbSession) -> Message:
    await db.execute(delete(Faculty).where(Faculty.id == faculty_id))
    await db.commit()
    return Message(detail="Faculty member removed")
