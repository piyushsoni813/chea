"""Global search spanning articles, opportunities, events, publications,
resources and the faculty directory. Each source contributes a capped slice so
one busy table can't crowd out the rest."""
from __future__ import annotations

from fastapi import APIRouter, Query
from sqlalchemy import or_, select

from app.api.deps import DbSession
from app.models.content import Article
from app.models.enums import ContentType
from app.models.event import Event
from app.models.faculty import Faculty
from app.models.opportunity import Opportunity
from app.models.publication import Publication
from app.models.resource import Resource
from app.schemas.search import SearchHit, SearchResults

router = APIRouter(prefix="/search", tags=["search"])

PER_SOURCE = 5


@router.get("", response_model=SearchResults)
async def global_search(
    db: DbSession,
    q: str = Query(min_length=2),
) -> SearchResults:
    like = f"%{q}%"
    hits: list[SearchHit] = []

    articles = (await db.scalars(
        select(Article)
        .where(Article.is_published.is_(True))
        .where(or_(Article.title.ilike(like), Article.excerpt.ilike(like)))
        .order_by(Article.published_at.desc().nullslast())
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type=ContentType.ARTICLE, id=a.id, title=a.title,
                  subtitle=a.kind.title(), image_url=a.cover_image_url)
        for a in articles
    ]

    opps = (await db.scalars(
        select(Opportunity)
        .where(Opportunity.is_active.is_(True))
        .where(or_(
            Opportunity.company.ilike(like),
            Opportunity.role.ilike(like),
            Opportunity.location.ilike(like),
        ))
        .order_by(Opportunity.created_at.desc())
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type=ContentType.OPPORTUNITY, id=o.id,
                  title=f"{o.role} @ {o.company}", subtitle=o.location,
                  image_url=o.company_logo_url)
        for o in opps
    ]

    events = (await db.scalars(
        select(Event)
        .where(or_(Event.title.ilike(like), Event.description.ilike(like)))
        .order_by(Event.starts_at.desc())
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type=ContentType.EVENT, id=e.id, title=e.title,
                  subtitle=e.venue, image_url=e.banner_url)
        for e in events
    ]

    pubs = (await db.scalars(
        select(Publication)
        .where(Publication.is_published.is_(True))
        .where(Publication.title.ilike(like))
        .order_by(Publication.published_at.desc().nullslast())
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type=ContentType.PUBLICATION, id=p.id, title=p.title,
                  subtitle=p.academic_year, image_url=p.cover_image_url)
        for p in pubs
    ]

    resources = (await db.scalars(
        select(Resource)
        .where(Resource.is_active.is_(True))
        .where(or_(Resource.title.ilike(like), Resource.subject.ilike(like)))
        .order_by(Resource.created_at.desc())
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type=ContentType.RESOURCE, id=r.id, title=r.title,
                  subtitle=r.subject, image_url=None)
        for r in resources
    ]

    faculty = (await db.scalars(
        select(Faculty)
        .where(or_(Faculty.name.ilike(like), Faculty.designation.ilike(like)))
        .order_by(Faculty.display_order, Faculty.name)
        .limit(PER_SOURCE)
    )).all()
    hits += [
        SearchHit(content_type="faculty", id=f.id, title=f.name,
                  subtitle=f.designation, image_url=f.photo_url)
        for f in faculty
    ]

    return SearchResults(query=q, total=len(hits), hits=hits)
