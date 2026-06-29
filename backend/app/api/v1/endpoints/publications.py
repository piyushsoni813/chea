"""Publications: browse by type/year, read, download (counted), admin CRUD."""
from __future__ import annotations

import datetime as dt
import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import delete, distinct, func, select

from app.api.deps import AdminUser, DbSession, OptionalUser, Pagination
from app.models.enums import ContentType
from app.models.publication import Publication
from app.schemas.common import Message, Page
from app.schemas.publication import PublicationCreate, PublicationRead, PublicationUpdate
from app.services.engagement_service import bookmarked_ids

router = APIRouter(prefix="/publications", tags=["publications"])


@router.get("", response_model=Page[PublicationRead])
async def list_publications(
    db: DbSession, pg: Pagination, user: OptionalUser,
    type: str | None = None, academic_year: str | None = None, q: str | None = None,
) -> Page[PublicationRead]:
    stmt = select(Publication).where(Publication.is_published.is_(True))
    if type:
        stmt = stmt.where(Publication.type == type)
    if academic_year:
        stmt = stmt.where(Publication.academic_year == academic_year)
    if q:
        stmt = stmt.where(Publication.title.ilike(f"%{q}%"))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Publication.academic_year.desc(), Publication.created_at.desc())
        .offset(pg.offset).limit(pg.size)
    )).all()
    ids = [p.id for p in rows]
    bmarks = await bookmarked_ids(db, user.id if user else None, ContentType.PUBLICATION, ids)
    items = []
    for p in rows:
        item = PublicationRead.model_validate(p)
        item.is_bookmarked = p.id in bmarks
        items.append(item)
    return Page.create(items, total or 0, pg.page, pg.size)


@router.get("/years", response_model=list[str])
async def list_years(db: DbSession) -> list[str]:
    rows = await db.scalars(
        select(distinct(Publication.academic_year)).order_by(Publication.academic_year.desc())
    )
    return list(rows.all())


@router.post("/{publication_id}/download", response_model=Message)
async def register_download(publication_id: uuid.UUID, db: DbSession) -> Message:
    pub = await db.scalar(select(Publication).where(Publication.id == publication_id))
    if not pub:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Publication not found")
    pub.download_count += 1
    await db.commit()
    return Message(detail=pub.pdf_url)


@router.post("", response_model=PublicationRead, status_code=201)
async def create_publication(data: PublicationCreate, user: AdminUser,
                             db: DbSession) -> PublicationRead:
    pub = Publication(**data.model_dump(),
                      published_at=dt.datetime.now(dt.timezone.utc) if data.is_published else None)
    db.add(pub)
    await db.commit()
    await db.refresh(pub)
    return PublicationRead.model_validate(pub)


@router.patch("/{publication_id}", response_model=PublicationRead)
async def update_publication(publication_id: uuid.UUID, data: PublicationUpdate,
                             user: AdminUser, db: DbSession) -> PublicationRead:
    pub = await db.scalar(select(Publication).where(Publication.id == publication_id))
    if not pub:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Publication not found")
    for f, v in data.model_dump(exclude_unset=True).items():
        setattr(pub, f, v)
    await db.commit()
    await db.refresh(pub)
    return PublicationRead.model_validate(pub)


@router.delete("/{publication_id}", response_model=Message)
async def delete_publication(publication_id: uuid.UUID, user: AdminUser,
                             db: DbSession) -> Message:
    await db.execute(delete(Publication).where(Publication.id == publication_id))
    await db.commit()
    return Message(detail="Publication deleted")
