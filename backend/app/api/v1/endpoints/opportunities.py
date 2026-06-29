"""Opportunities: list/filter/sort, detail, favorite, and staff CRUD."""
from __future__ import annotations

import datetime as dt
import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import delete, func, select

from app.api.deps import AdminUser, DbSession, OptionalUser, Pagination
from app.models.enums import ContentType
from app.models.opportunity import Opportunity
from app.schemas.common import Message, Page
from app.schemas.opportunity import OpportunityCreate, OpportunityRead, OpportunityUpdate
from app.services.engagement_service import bookmarked_ids, favorited_ids

router = APIRouter(prefix="/opportunities", tags=["opportunities"])

_SORTS = {
    "deadline": Opportunity.deadline.asc().nullslast(),
    "-deadline": Opportunity.deadline.desc().nullslast(),
    "newest": Opportunity.created_at.desc(),
    "oldest": Opportunity.created_at.asc(),
    "company": Opportunity.company.asc(),
}


@router.get("", response_model=Page[OpportunityRead])
async def list_opportunities(
    db: DbSession,
    pg: Pagination,
    user: OptionalUser,
    type: str | None = Query(None, description="internship|placement|project|research|scholarship"),
    q: str | None = None,
    location: str | None = None,
    active_only: bool = True,
    sort: str = Query("newest", description="newest|oldest|deadline|-deadline|company"),
) -> Page[OpportunityRead]:
    stmt = select(Opportunity)
    if active_only:
        stmt = stmt.where(Opportunity.is_active.is_(True))
    if type:
        stmt = stmt.where(Opportunity.type == type)
    if location:
        stmt = stmt.where(Opportunity.location.ilike(f"%{location}%"))
    if q:
        like = f"%{q}%"
        stmt = stmt.where(Opportunity.company.ilike(like) | Opportunity.role.ilike(like))

    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(_SORTS.get(sort, Opportunity.created_at.desc()))
        .offset(pg.offset).limit(pg.size)
    )).all()

    ids = [o.id for o in rows]
    favs = await favorited_ids(db, user.id if user else None, ContentType.OPPORTUNITY, ids)
    bmarks = await bookmarked_ids(db, user.id if user else None, ContentType.OPPORTUNITY, ids)
    items = []
    for o in rows:
        item = OpportunityRead.model_validate(o)
        item.is_favorited = o.id in favs
        item.is_bookmarked = o.id in bmarks
        items.append(item)
    return Page.create(items, total or 0, pg.page, pg.size)


@router.get("/{opportunity_id}", response_model=OpportunityRead)
async def get_opportunity(opportunity_id: uuid.UUID, db: DbSession,
                          user: OptionalUser) -> OpportunityRead:
    opp = await db.scalar(select(Opportunity).where(Opportunity.id == opportunity_id))
    if not opp:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Opportunity not found")
    item = OpportunityRead.model_validate(opp)
    if user:
        item.is_favorited = bool(
            await favorited_ids(db, user.id, ContentType.OPPORTUNITY, [opp.id])
        )
        item.is_bookmarked = bool(
            await bookmarked_ids(db, user.id, ContentType.OPPORTUNITY, [opp.id])
        )
    return item


@router.post("", response_model=OpportunityRead, status_code=201)
async def create_opportunity(data: OpportunityCreate, user: AdminUser,
                             db: DbSession) -> OpportunityRead:
    opp = Opportunity(**data.model_dump())
    db.add(opp)
    await db.commit()
    await db.refresh(opp)
    return OpportunityRead.model_validate(opp)


@router.patch("/{opportunity_id}", response_model=OpportunityRead)
async def update_opportunity(opportunity_id: uuid.UUID, data: OpportunityUpdate,
                             user: AdminUser, db: DbSession) -> OpportunityRead:
    opp = await db.scalar(select(Opportunity).where(Opportunity.id == opportunity_id))
    if not opp:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Opportunity not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(opp, field, value)
    await db.commit()
    await db.refresh(opp)
    return OpportunityRead.model_validate(opp)


@router.delete("/{opportunity_id}", response_model=Message)
async def delete_opportunity(opportunity_id: uuid.UUID, user: AdminUser,
                             db: DbSession) -> Message:
    await db.execute(delete(Opportunity).where(Opportunity.id == opportunity_id))
    await db.commit()
    return Message(detail="Opportunity deleted")
