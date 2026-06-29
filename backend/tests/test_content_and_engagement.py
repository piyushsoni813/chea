"""Content listing, admin-gated writes, search and engagement."""
import pytest

pytestmark = pytest.mark.asyncio(loop_scope="session")

from app.core.config import settings


async def _student_headers(client, email="student1@students.chea.edu"):
    r = await client.post("/api/v1/auth/register", json={
        "email": email, "password": "secret123", "full_name": "S One"})
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


async def test_articles_list_is_public_and_paginated(client):
    r = await client.get("/api/v1/articles?page=1&size=5")
    assert r.status_code == 200
    body = r.json()
    assert set(["items", "total", "page", "size", "pages"]).issubset(body.keys())


async def test_article_create_requires_admin(client):
    headers = await _student_headers(client)
    r = await client.post("/api/v1/articles", headers=headers, json={
        "title": "Nope", "kind": "news", "category": "department_news",
        "body": "body"})
    assert r.status_code == 403


async def test_search_requires_min_length(client):
    r = await client.get("/api/v1/search?q=a")
    assert r.status_code == 422
    r = await client.get("/api/v1/search?q=process")
    assert r.status_code == 200
    assert "hits" in r.json()


async def test_bookmark_toggle_roundtrip(client, db):
    # Seed one article directly so there is something to bookmark.
    from app.models.content import Article
    from app.utils.slug import unique_slug
    art = Article(title="Seeded", slug=unique_slug("Seeded"), kind="news",
                  category="department_news", body="hello world",
                  reading_minutes=1, is_published=True)
    db.add(art)
    await db.commit()

    headers = await _student_headers(client, "bm@students.chea.edu")
    on = await client.post("/api/v1/bookmarks/toggle", headers=headers,
                           json={"content_type": "article", "content_id": str(art.id)})
    assert on.status_code == 200 and on.json()["active"] is True

    mine = await client.get("/api/v1/bookmarks", headers=headers)
    assert mine.status_code == 200
    assert any(item["id"] == str(art.id) for item in mine.json()["items"])

    off = await client.post("/api/v1/bookmarks/toggle", headers=headers,
                            json={"content_type": "article", "content_id": str(art.id)})
    assert off.status_code == 200 and off.json()["active"] is False


async def test_admin_stats_blocked_for_students(client):
    headers = await _student_headers(client, "nosy@students.chea.edu")
    r = await client.get("/api/v1/admin/stats", headers=headers)
    assert r.status_code == 403


async def test_form_submission_history(client):
    headers = await _student_headers(client, "former@students.chea.edu")
    r = await client.post("/api/v1/forms/submit", headers=headers, json={
        "form_type": "feedback", "payload": {"rating": 5}})
    assert r.status_code == 201
    assert r.json()["status"] == "pending"
    mine = await client.get("/api/v1/forms/mine", headers=headers)
    assert mine.json()["total"] == 1
