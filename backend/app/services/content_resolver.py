"""Resolve generic (content_type, content_id) references into display cards.

Bookmarks and favorites store only a type and an id. To render a saved-items
list the client needs a title, a subtitle and an image for each one. This
batch-loads the underlying rows per content type so a mixed list of saved
articles, events, publications and resources resolves in a handful of queries
rather than one per item.
"""
from __future__ import annotations

import uuid
from collections import defaultdict

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.content import Article
from app.models.enums import ContentType
from app.models.event import Event
from app.models.opportunity import Opportunity
from app.models.publication import Publication
from app.models.resource import Resource
from app.schemas.search import SearchHit


async def resolve_items(
    db: AsyncSession, refs: list[tuple[str, uuid.UUID]],
) -> list[SearchHit]:
    """Resolve (content_type, content_id) pairs, preserving input order."""
    by_type: dict[str, list[uuid.UUID]] = defaultdict(list)
    for ctype, cid in refs:
        by_type[ctype].append(cid)

    found: dict[tuple[str, uuid.UUID], SearchHit] = {}

    if by_type.get(ContentType.ARTICLE):
        rows = (await db.scalars(
            select(Article).where(Article.id.in_(by_type[ContentType.ARTICLE]))
        )).all()
        for a in rows:
            found[(ContentType.ARTICLE, a.id)] = SearchHit(
                content_type=ContentType.ARTICLE, id=a.id, title=a.title,
                subtitle=a.excerpt, image_url=a.cover_image_url,
            )

    if by_type.get(ContentType.OPPORTUNITY):
        rows = (await db.scalars(
            select(Opportunity).where(Opportunity.id.in_(by_type[ContentType.OPPORTUNITY]))
        )).all()
        for o in rows:
            found[(ContentType.OPPORTUNITY, o.id)] = SearchHit(
                content_type=ContentType.OPPORTUNITY, id=o.id,
                title=f"{o.role} @ {o.company}", subtitle=o.location,
                image_url=o.company_logo_url,
            )

    if by_type.get(ContentType.EVENT):
        rows = (await db.scalars(
            select(Event).where(Event.id.in_(by_type[ContentType.EVENT]))
        )).all()
        for e in rows:
            found[(ContentType.EVENT, e.id)] = SearchHit(
                content_type=ContentType.EVENT, id=e.id, title=e.title,
                subtitle=e.venue, image_url=e.banner_url,
            )

    if by_type.get(ContentType.PUBLICATION):
        rows = (await db.scalars(
            select(Publication).where(Publication.id.in_(by_type[ContentType.PUBLICATION]))
        )).all()
        for p in rows:
            found[(ContentType.PUBLICATION, p.id)] = SearchHit(
                content_type=ContentType.PUBLICATION, id=p.id, title=p.title,
                subtitle=p.academic_year, image_url=p.cover_image_url,
            )

    if by_type.get(ContentType.RESOURCE):
        rows = (await db.scalars(
            select(Resource).where(Resource.id.in_(by_type[ContentType.RESOURCE]))
        )).all()
        for r in rows:
            found[(ContentType.RESOURCE, r.id)] = SearchHit(
                content_type=ContentType.RESOURCE, id=r.id, title=r.title,
                subtitle=r.subject, image_url=None,
            )

    # Preserve original ordering; drop refs whose target has since been deleted.
    return [found[(ctype, cid)] for ctype, cid in refs if (ctype, cid) in found]
