"""News + student blogs: list, read, like, comment, plus staff authoring.

A single set of endpoints serves both kinds; the ``kind`` query param filters
news vs blogs. List responses are annotated with per-user liked/bookmarked
flags so the client can render correct state in one round trip.
"""
from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import delete, func, select
from sqlalchemy.orm import selectinload

from app.api.deps import CurrentUser, DbSession, OptionalUser, Pagination, StaffUser
from app.models.content import Article, ArticleComment, ArticleLike
from app.models.enums import ContentType
from app.schemas.article import (
    ArticleCreate,
    ArticleDetail,
    ArticleListItem,
    ArticleUpdate,
    CommentCreate,
    CommentRead,
)
from app.schemas.common import Message, Page
from app.services.engagement_service import bookmarked_ids
from app.utils.reading_time import estimate_reading_minutes
from app.utils.slug import unique_slug

router = APIRouter(prefix="/articles", tags=["articles"])


async def _counts(db: DbSession, article_ids: list[uuid.UUID]) -> tuple[dict, dict]:
    if not article_ids:
        return {}, {}
    likes = dict((await db.execute(
        select(ArticleLike.article_id, func.count())
        .where(ArticleLike.article_id.in_(article_ids))
        .group_by(ArticleLike.article_id)
    )).all())
    comments = dict((await db.execute(
        select(ArticleComment.article_id, func.count())
        .where(ArticleComment.article_id.in_(article_ids))
        .group_by(ArticleComment.article_id)
    )).all())
    return likes, comments


@router.get("", response_model=Page[ArticleListItem])
async def list_articles(
    db: DbSession,
    pg: Pagination,
    user: OptionalUser,
    kind: str | None = Query(None, description="news | blog"),
    category: str | None = None,
    q: str | None = Query(None, description="search title/excerpt"),
    featured: bool | None = None,
) -> Page[ArticleListItem]:
    stmt = select(Article).where(Article.is_published.is_(True))
    if kind:
        stmt = stmt.where(Article.kind == kind)
    if category:
        stmt = stmt.where(Article.category == category)
    if featured is not None:
        stmt = stmt.where(Article.is_featured.is_(featured))
    if q:
        like = f"%{q}%"
        stmt = stmt.where(Article.title.ilike(like) | Article.excerpt.ilike(like))

    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.options(selectinload(Article.author))
        .order_by(Article.published_at.desc().nullslast(), Article.created_at.desc())
        .offset(pg.offset).limit(pg.size)
    )).all()

    ids = [a.id for a in rows]
    likes, comments = await _counts(db, ids)
    bmarks = await bookmarked_ids(db, user.id if user else None, ContentType.ARTICLE, ids)

    items = []
    for a in rows:
        item = ArticleListItem.model_validate(a)
        item.like_count = likes.get(a.id, 0)
        item.comment_count = comments.get(a.id, 0)
        items.append(item)
    return Page.create(items, total or 0, pg.page, pg.size)


@router.get("/{slug}", response_model=ArticleDetail)
async def get_article(slug: str, db: DbSession, user: OptionalUser) -> ArticleDetail:
    article = await db.scalar(
        select(Article).options(selectinload(Article.author)).where(Article.slug == slug)
    )
    if not article or (not article.is_published and user is None):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Article not found")

    article.view_count += 1
    await db.commit()
    await db.refresh(article)

    likes, comments = await _counts(db, [article.id])
    detail = ArticleDetail.model_validate(article)
    detail.like_count = likes.get(article.id, 0)
    detail.comment_count = comments.get(article.id, 0)
    if user:
        detail.is_liked = bool(await db.scalar(
            select(ArticleLike).where(ArticleLike.article_id == article.id,
                                      ArticleLike.user_id == user.id)
        ))
        detail.is_bookmarked = bool(
            await bookmarked_ids(db, user.id, ContentType.ARTICLE, [article.id])
        )
    return detail


@router.post("/{article_id}/like", response_model=Message)
async def toggle_like(article_id: uuid.UUID, user: CurrentUser, db: DbSession) -> Message:
    existing = await db.scalar(
        select(ArticleLike).where(ArticleLike.article_id == article_id,
                                  ArticleLike.user_id == user.id)
    )
    if existing:
        await db.delete(existing)
        await db.commit()
        return Message(detail="unliked")
    if not await db.scalar(select(Article.id).where(Article.id == article_id)):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Article not found")
    db.add(ArticleLike(article_id=article_id, user_id=user.id))
    await db.commit()
    return Message(detail="liked")


@router.get("/{article_id}/comments", response_model=list[CommentRead])
async def list_comments(article_id: uuid.UUID, db: DbSession) -> list[CommentRead]:
    rows = (await db.scalars(
        select(ArticleComment)
        .options(selectinload(ArticleComment.user))
        .where(ArticleComment.article_id == article_id)
        .order_by(ArticleComment.created_at.asc())
    )).all()
    return [CommentRead.model_validate(c) for c in rows]


@router.post("/{article_id}/comments", response_model=CommentRead, status_code=201)
async def add_comment(article_id: uuid.UUID, data: CommentCreate,
                      user: CurrentUser, db: DbSession) -> CommentRead:
    if not await db.scalar(select(Article.id).where(Article.id == article_id)):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Article not found")
    comment = ArticleComment(
        article_id=article_id, user_id=user.id,
        body=data.body, parent_id=data.parent_id,
    )
    db.add(comment)
    await db.commit()
    loaded = await db.scalar(
        select(ArticleComment).options(selectinload(ArticleComment.user))
        .where(ArticleComment.id == comment.id)
    )
    return CommentRead.model_validate(loaded)


@router.delete("/comments/{comment_id}", response_model=Message)
async def delete_comment(comment_id: uuid.UUID, user: CurrentUser, db: DbSession) -> Message:
    comment = await db.scalar(select(ArticleComment).where(ArticleComment.id == comment_id))
    if not comment:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Comment not found")
    is_owner = comment.user_id == user.id
    is_staff = user.role in {"faculty", "admin", "super_admin"}
    if not (is_owner or is_staff):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not allowed")
    await db.delete(comment)
    await db.commit()
    return Message(detail="Comment deleted")


# ----- Staff authoring -----

@router.post("", response_model=ArticleDetail, status_code=201)
async def create_article(data: ArticleCreate, user: StaffUser, db: DbSession) -> ArticleDetail:
    import datetime as dt
    article = Article(
        **data.model_dump(),
        slug=unique_slug(data.title),
        reading_minutes=estimate_reading_minutes(data.body),
        author_id=user.id,
        published_at=dt.datetime.now(dt.timezone.utc) if data.is_published else None,
    )
    db.add(article)
    await db.commit()
    loaded = await db.scalar(
        select(Article).options(selectinload(Article.author)).where(Article.id == article.id)
    )
    return ArticleDetail.model_validate(loaded)


@router.patch("/{article_id}", response_model=ArticleDetail)
async def update_article(article_id: uuid.UUID, data: ArticleUpdate,
                         user: StaffUser, db: DbSession) -> ArticleDetail:
    article = await db.scalar(select(Article).where(Article.id == article_id))
    if not article:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Article not found")
    updates = data.model_dump(exclude_unset=True)
    if "body" in updates:
        article.reading_minutes = estimate_reading_minutes(updates["body"])
    for field, value in updates.items():
        setattr(article, field, value)
    await db.commit()
    loaded = await db.scalar(
        select(Article).options(selectinload(Article.author)).where(Article.id == article.id)
    )
    return ArticleDetail.model_validate(loaded)


@router.delete("/{article_id}", response_model=Message)
async def delete_article(article_id: uuid.UUID, user: StaffUser, db: DbSession) -> Message:
    await db.execute(delete(Article).where(Article.id == article_id))
    await db.commit()
    return Message(detail="Article deleted")
