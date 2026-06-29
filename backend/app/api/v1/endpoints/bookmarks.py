"""Bookmarks: toggle any content type, list resolved saved items."""
from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import func, select

from app.api.deps import CurrentUser, DbSession, Pagination
from app.models.engagement import Bookmark
from app.schemas.common import Page
from app.schemas.engagement import ToggleRequest, ToggleResponse
from app.schemas.search import SearchHit
from app.services.content_resolver import resolve_items
from app.services.engagement_service import toggle_bookmark

router = APIRouter(prefix="/bookmarks", tags=["bookmarks"])


@router.post("/toggle", response_model=ToggleResponse)
async def toggle(data: ToggleRequest, user: CurrentUser, db: DbSession) -> ToggleResponse:
    active = await toggle_bookmark(db, user.id, data.content_type, data.content_id)
    return ToggleResponse(active=active)


@router.get("", response_model=Page[SearchHit])
async def my_bookmarks(
    user: CurrentUser, db: DbSession, pg: Pagination,
    content_type: str | None = None,
) -> Page[SearchHit]:
    stmt = select(Bookmark).where(Bookmark.user_id == user.id)
    if content_type:
        stmt = stmt.where(Bookmark.content_type == content_type)
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Bookmark.created_at.desc()).offset(pg.offset).limit(pg.size)
    )).all()
    refs = [(b.content_type, b.content_id) for b in rows]
    items = await resolve_items(db, refs)
    return Page.create(items, total or 0, pg.page, pg.size)
