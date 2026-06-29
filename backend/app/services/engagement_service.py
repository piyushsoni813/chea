"""Helpers for toggling and resolving bookmarks/favorites efficiently."""
from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.engagement import Bookmark, Favorite


async def toggle_bookmark(db: AsyncSession, user_id: uuid.UUID,
                          content_type: str, content_id: uuid.UUID) -> bool:
    existing = await db.scalar(
        select(Bookmark).where(
            Bookmark.user_id == user_id,
            Bookmark.content_type == content_type,
            Bookmark.content_id == content_id,
        )
    )
    if existing:
        await db.delete(existing)
        await db.commit()
        return False
    db.add(Bookmark(user_id=user_id, content_type=content_type, content_id=content_id))
    await db.commit()
    return True


async def toggle_favorite(db: AsyncSession, user_id: uuid.UUID,
                          content_type: str, content_id: uuid.UUID) -> bool:
    existing = await db.scalar(
        select(Favorite).where(
            Favorite.user_id == user_id,
            Favorite.content_type == content_type,
            Favorite.content_id == content_id,
        )
    )
    if existing:
        await db.delete(existing)
        await db.commit()
        return False
    db.add(Favorite(user_id=user_id, content_type=content_type, content_id=content_id))
    await db.commit()
    return True


async def bookmarked_ids(db: AsyncSession, user_id: uuid.UUID | None,
                         content_type: str, ids: list[uuid.UUID]) -> set[uuid.UUID]:
    if not user_id or not ids:
        return set()
    rows = await db.scalars(
        select(Bookmark.content_id).where(
            Bookmark.user_id == user_id,
            Bookmark.content_type == content_type,
            Bookmark.content_id.in_(ids),
        )
    )
    return set(rows.all())


async def favorited_ids(db: AsyncSession, user_id: uuid.UUID | None,
                        content_type: str, ids: list[uuid.UUID]) -> set[uuid.UUID]:
    if not user_id or not ids:
        return set()
    rows = await db.scalars(
        select(Favorite.content_id).where(
            Favorite.user_id == user_id,
            Favorite.content_type == content_type,
            Favorite.content_id.in_(ids),
        )
    )
    return set(rows.all())
