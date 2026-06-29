"""Import every model so Base.metadata is fully populated (Alembic, create_all)."""
from app.db.base import Base
from app.models.content import Article, ArticleComment, ArticleLike
from app.models.engagement import Bookmark, Favorite
from app.models.event import (
    Event,
    EventGalleryImage,
    EventRegistration,
    EventScheduleItem,
)
from app.models.faculty import Contact, Faculty
from app.models.form import FormSubmission
from app.models.notification import Notification
from app.models.opportunity import Opportunity
from app.models.publication import Publication
from app.models.resource import Resource
from app.models.upload import UploadedFile
from app.models.user import DeviceToken, RefreshToken, StudentProfile, User

__all__ = [
    "Base",
    "User",
    "StudentProfile",
    "RefreshToken",
    "DeviceToken",
    "Faculty",
    "Contact",
    "Article",
    "ArticleComment",
    "ArticleLike",
    "Opportunity",
    "Event",
    "EventGalleryImage",
    "EventScheduleItem",
    "EventRegistration",
    "Publication",
    "Resource",
    "FormSubmission",
    "Notification",
    "Bookmark",
    "Favorite",
    "UploadedFile",
]
