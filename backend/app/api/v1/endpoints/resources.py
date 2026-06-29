"""Resources: notes, papers, books, software, links, repos. Download-counted."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import delete, func, select

from app.api.deps import AdminUser, DbSession, OptionalUser, Pagination
from app.models.enums import ContentType
from app.models.resource import Resource
from app.schemas.common import Message, Page
from app.schemas.resource import ResourceCreate, ResourceRead, ResourceUpdate
from app.services.engagement_service import bookmarked_ids

router = APIRouter(prefix="/resources", tags=["resources"])


@router.get("", response_model=Page[ResourceRead])
async def list_resources(
    db: DbSession, pg: Pagination, user: OptionalUser,
    type: str | None = None, subject: str | None = None,
    semester: int | None = None, q: str | None = None,
) -> Page[ResourceRead]:
    stmt = select(Resource).where(Resource.is_active.is_(True))
    if type:
        stmt = stmt.where(Resource.type == type)
    if subject:
        stmt = stmt.where(Resource.subject.ilike(f"%{subject}%"))
    if semester:
        stmt = stmt.where(Resource.semester == semester)
    if q:
        stmt = stmt.where(Resource.title.ilike(f"%{q}%"))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Resource.created_at.desc()).offset(pg.offset).limit(pg.size)
    )).all()
    ids = [r.id for r in rows]
    bmarks = await bookmarked_ids(db, user.id if user else None, ContentType.RESOURCE, ids)
    items = []
    for r in rows:
        item = ResourceRead.model_validate(r)
        item.is_bookmarked = r.id in bmarks
        items.append(item)
    return Page.create(items, total or 0, pg.page, pg.size)


@router.post("/{resource_id}/download", response_model=Message)
async def register_download(resource_id: uuid.UUID, db: DbSession) -> Message:
    res = await db.scalar(select(Resource).where(Resource.id == resource_id))
    if not res:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Resource not found")
    res.download_count += 1
    await db.commit()
    return Message(detail=res.file_url or res.external_url or "")


@router.post("", response_model=ResourceRead, status_code=201)
async def create_resource(data: ResourceCreate, user: AdminUser, db: DbSession) -> ResourceRead:
    res = Resource(**data.model_dump())
    db.add(res)
    await db.commit()
    await db.refresh(res)
    return ResourceRead.model_validate(res)


@router.patch("/{resource_id}", response_model=ResourceRead)
async def update_resource(resource_id: uuid.UUID, data: ResourceUpdate,
                          user: AdminUser, db: DbSession) -> ResourceRead:
    res = await db.scalar(select(Resource).where(Resource.id == resource_id))
    if not res:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Resource not found")
    for f, v in data.model_dump(exclude_unset=True).items():
        setattr(res, f, v)
    await db.commit()
    await db.refresh(res)
    return ResourceRead.model_validate(res)


@router.delete("/{resource_id}", response_model=Message)
async def delete_resource(resource_id: uuid.UUID, user: AdminUser, db: DbSession) -> Message:
    await db.execute(delete(Resource).where(Resource.id == resource_id))
    await db.commit()
    return Message(detail="Resource deleted")
