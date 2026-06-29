"""Enumerations used across models and schemas.

Stored as plain strings in the database (not native PG enum types) so that
adding a new value never requires an ALTER TYPE migration. Validation of
allowed values happens at the Pydantic layer.
"""
from enum import StrEnum


class UserRole(StrEnum):
    STUDENT = "student"
    FACULTY = "faculty"
    ADMIN = "admin"
    SUPER_ADMIN = "super_admin"


class ArticleKind(StrEnum):
    NEWS = "news"
    BLOG = "blog"


class ArticleCategory(StrEnum):
    # News categories
    DEPARTMENT_NEWS = "department_news"
    ANNOUNCEMENT = "announcement"
    ACHIEVEMENT = "achievement"
    RESEARCH = "research"
    FEATURE = "feature"
    # Blog categories
    INTERNSHIP_EXPERIENCE = "internship_experience"
    PLACEMENT_EXPERIENCE = "placement_experience"
    RESEARCH_JOURNEY = "research_journey"
    STUDY_TIPS = "study_tips"
    HIGHER_STUDIES = "higher_studies"
    CLUB_ACTIVITIES = "club_activities"


class OpportunityType(StrEnum):
    INTERNSHIP = "internship"
    PLACEMENT = "placement"
    PROJECT = "project"
    RESEARCH = "research"
    SCHOLARSHIP = "scholarship"


class EventType(StrEnum):
    TRADITIONAL_DAY = "traditional_day"
    FRESHERS = "freshers"
    FAREWELL = "farewell"
    INDUSTRIAL_VISIT = "industrial_visit"
    GUEST_LECTURE = "guest_lecture"
    SEMINAR = "seminar"
    WORKSHOP = "workshop"


class RegistrationStatus(StrEnum):
    REGISTERED = "registered"
    CHECKED_IN = "checked_in"
    CANCELLED = "cancelled"


class PublicationType(StrEnum):
    MAGAZINE = "magazine"
    GAZETTE = "gazette"
    RESEARCH_PAPER = "research_paper"
    ANNUAL_REPORT = "annual_report"
    NEWSLETTER = "newsletter"


class ResourceType(StrEnum):
    RESUME_REPOSITORY = "resume_repository"
    PLACEMENT_REPOSITORY = "placement_repository"
    STUDY_MATERIAL = "study_material"
    NOTES = "notes"
    PREVIOUS_YEAR_PAPER = "previous_year_paper"
    BOOK = "book"
    SOFTWARE = "software"
    USEFUL_LINK = "useful_link"


class FormType(StrEnum):
    MEMBERSHIP_REGISTRATION = "membership_registration"
    EVENT_REGISTRATION = "event_registration"
    FEEDBACK = "feedback"
    COMPLAINT = "complaint"
    CERTIFICATE_REQUEST = "certificate_request"
    RESUME_SUBMISSION = "resume_submission"
    PAYMENT_SCREENSHOT = "payment_screenshot"


class SubmissionStatus(StrEnum):
    PENDING = "pending"
    REVIEWED = "reviewed"
    APPROVED = "approved"
    REJECTED = "rejected"


class NotificationType(StrEnum):
    INTERNSHIP_ALERT = "internship_alert"
    PLACEMENT_ALERT = "placement_alert"
    ANNOUNCEMENT = "announcement"
    EVENT_REMINDER = "event_reminder"
    PUBLICATION_RELEASE = "publication_release"
    GENERIC = "generic"


class ContactCategory(StrEnum):
    FACULTY = "faculty"
    STUDENT_COUNCIL = "student_council"
    PLACEMENT_COORDINATOR = "placement_coordinator"
    LAB_STAFF = "lab_staff"
    DEPARTMENT_OFFICE = "department_office"


class ContentType(StrEnum):
    """Targets for generic bookmarks / favorites."""
    ARTICLE = "article"
    OPPORTUNITY = "opportunity"
    EVENT = "event"
    PUBLICATION = "publication"
    RESOURCE = "resource"
