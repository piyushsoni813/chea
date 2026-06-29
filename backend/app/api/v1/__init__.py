"""Versioned API router. Every endpoint module is mounted here under /api/v1."""
from fastapi import APIRouter

from app.api.v1.endpoints import (
    admin,
    articles,
    auth,
    bookmarks,
    contacts,
    events,
    faculty,
    favorites,
    forms,
    notifications,
    opportunities,
    profile,
    publications,
    resources,
    search,
    uploads,
)

api_router = APIRouter()
api_router.include_router(auth.router)
api_router.include_router(profile.router)
api_router.include_router(articles.router)
api_router.include_router(opportunities.router)
api_router.include_router(events.router)
api_router.include_router(publications.router)
api_router.include_router(resources.router)
api_router.include_router(faculty.router)
api_router.include_router(contacts.router)
api_router.include_router(forms.router)
api_router.include_router(notifications.router)
api_router.include_router(bookmarks.router)
api_router.include_router(favorites.router)
api_router.include_router(search.router)
api_router.include_router(uploads.router)
api_router.include_router(admin.router)
