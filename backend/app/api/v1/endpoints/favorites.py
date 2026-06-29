"""Favorites: toggle (typically opportunities), list resolved saved items."""
from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import func, select

from app.api.deps import CurrentUser, DbSession, Pagination
from app.models.engagement import Favorite
from app.schemas.common import Page
from app.schemas.engagement import ToggleRequest, ToggleResponse
from app.schemas.search import SearchHit
from app.services.content_resolver import resolve_items
from app.services.engagement_service import toggle_favorite

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.post("/toggle", response_model=ToggleResponse)
async def toggle(data: ToggleRequest, user: CurrentUser, db: DbSession) -> ToggleResponse:
    active = await toggle_favorite(db, user.id, data.content_type, data.content_id)
    return ToggleResponse(active=active)


@router.get("", response_model=Page[SearchHit])
async def my_favorites(
    user: CurrentUser, db: DbSession, pg: Pagination,
    content_type: str | None = None,
) -> Page[SearchHit]:
    stmt = select(Favorite).where(Favorite.user_id == user.id)
    if content_type:
        stmt = stmt.where(Favorite.content_type == content_type)
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Favorite.created_at.desc()).offset(pg.offset).limit(pg.size)
    )).all()
    refs = [(f.content_type, f.content_id) for f in rows]
    items = await resolve_items(db, refs)
    return Page.create(items, total or 0, pg.page, pg.size)
