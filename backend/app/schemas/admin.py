"""Admin dashboard analytics schema."""
from __future__ import annotations

from pydantic import BaseModel


class DashboardStats(BaseModel):
    total_users: int
    total_students: int
    total_faculty: int
    total_articles: int
    total_opportunities: int
    active_opportunities: int
    total_events: int
    upcoming_events: int
    total_publications: int
    total_resources: int
    pending_forms: int
    notifications_sent: int
