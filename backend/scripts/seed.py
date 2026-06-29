"""Seed the database with a realistic starter dataset.

Idempotent at the coarse level: if the faculty table already has rows the seed
assumes it has run before and exits, so re-running never piles up duplicates.
Run with `python -m scripts.seed` (or via the Makefile / docker compose).
"""
from __future__ import annotations

import asyncio
import datetime as dt

from sqlalchemy import func, select

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.content import Article
from app.models.enums import (
    ArticleCategory,
    ArticleKind,
    ContactCategory,
    EventType,
    OpportunityType,
    PublicationType,
    ResourceType,
    UserRole,
)
from app.models.event import Event, EventGalleryImage, EventScheduleItem
from app.models.faculty import Contact, Faculty
from app.models.opportunity import Opportunity
from app.models.publication import Publication
from app.models.resource import Resource
from app.models.user import User
from app.utils.reading_time import estimate_reading_minutes
from app.utils.slug import unique_slug

UTC = dt.timezone.utc
now = dt.datetime.now(UTC)


def days(n: int) -> dt.datetime:
    return now + dt.timedelta(days=n)


async def seed_superuser(db) -> User:
    user = await db.scalar(
        select(User).where(User.email == settings.FIRST_SUPERUSER_EMAIL)
    )
    if user:
        return user
    user = User(
        email=settings.FIRST_SUPERUSER_EMAIL,
        full_name="CHEA Administrator",
        hashed_password=hash_password(settings.FIRST_SUPERUSER_PASSWORD),
        role=UserRole.SUPER_ADMIN,
        is_active=True,
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    return user


def faculty_rows() -> list[Faculty]:
    return [
        Faculty(
            name="Dr. Anjali Mehta", designation="Professor & Head of Department",
            email="anjali.mehta@chea.edu", phone="+91 98200 11001",
            office="ChE Block, Room 301", office_hours="Mon–Wed, 3–5 PM",
            research_interests=["Process Systems Engineering", "Reaction Kinetics"],
            google_scholar_url="https://scholar.google.com/citations?user=demo1",
            linkedin_url="https://www.linkedin.com/in/demo-anjali", display_order=1,
        ),
        Faculty(
            name="Dr. Rakesh Iyer", designation="Professor",
            email="rakesh.iyer@chea.edu", phone="+91 98200 11002",
            office="ChE Block, Room 214", office_hours="Tue–Thu, 11 AM–1 PM",
            research_interests=["Transport Phenomena", "Membrane Separation"],
            display_order=2,
        ),
        Faculty(
            name="Dr. Sneha Kulkarni", designation="Associate Professor",
            email="sneha.kulkarni@chea.edu", phone="+91 98200 11003",
            office="ChE Block, Room 118", office_hours="Fri, 2–4 PM",
            research_interests=["Thermodynamics", "Process Simulation"],
            display_order=3,
        ),
        Faculty(
            name="Dr. Imran Shaikh", designation="Assistant Professor",
            email="imran.shaikh@chea.edu", phone="+91 98200 11004",
            office="ChE Block, Room 109", office_hours="Mon, 10 AM–12 PM",
            research_interests=["Process Control", "Machine Learning for Chemicals"],
            display_order=4,
        ),
    ]


def contact_rows() -> list[Contact]:
    return [
        Contact(name="Department Office", category=ContactCategory.DEPARTMENT_OFFICE,
                role="General Enquiries", email="office@chea.edu",
                phone="+91 22 4000 5000", display_order=1),
        Contact(name="Aarav Sharma", category=ContactCategory.STUDENT_COUNCIL,
                role="General Secretary", email="gsec@chea.edu",
                phone="+91 99000 22001", whatsapp="+91 99000 22001", display_order=2),
        Contact(name="Diya Patel", category=ContactCategory.PLACEMENT_COORDINATOR,
                role="Placement Coordinator", email="placements@chea.edu",
                phone="+91 99000 22002", whatsapp="+91 99000 22002", display_order=3),
        Contact(name="Mr. Suresh Pawar", category=ContactCategory.LAB_STAFF,
                role="Senior Lab Technician", email="labs@chea.edu",
                phone="+91 99000 22003", display_order=4),
    ]


def article_rows(author_id) -> list[Article]:
    drafts = [
        ("Department Secures Major Research Grant",
         ArticleKind.NEWS, ArticleCategory.ACHIEVEMENT,
         "The department has been awarded a competitive grant to advance work on "
         "sustainable catalysis.",
         "## A milestone for the department\n\nThe Chemical Engineering department "
         "has received a substantial research grant supporting a three-year program "
         "on sustainable catalysis. The funding will equip a new reaction "
         "engineering lab and support several graduate fellowships.\n\nWork begins "
         "next semester, with undergraduate research positions opening in parallel.",
         True, True),
        ("Annual Tech Symposium Announced",
         ArticleKind.NEWS, ArticleCategory.ANNOUNCEMENT,
         "Save the date for this year's flagship technical symposium.",
         "## Symposium\n\nThe annual technical symposium returns with keynote talks, "
         "a poster competition and an industry networking evening. Registration "
         "opens through the Events tab.",
         True, False),
        ("My Summer at a Process Engineering Internship",
         ArticleKind.BLOG, ArticleCategory.INTERNSHIP_EXPERIENCE,
         "What I learned interning on a live plant optimization project.",
         "## How it started\n\nI spent the summer with a specialty chemicals "
         "manufacturer, working alongside their process engineering team.\n\n## What "
         "I actually did\n\nMost of my time went into data reconciliation and a small "
         "simulation study. The biggest lesson: real plants are messy, and good "
         "assumptions matter more than fancy models.\n\n## Advice\n\nStart asking "
         "questions early and keep a daily log.",
         True, True),
        ("Cracking Placements: A Final-Year Retrospective",
         ArticleKind.BLOG, ArticleCategory.PLACEMENT_EXPERIENCE,
         "An honest account of the placement season, prep and interviews.",
         "## Preparation\n\nI focused on core subjects, basic data structures and "
         "clear communication. Mock interviews with friends helped more than anything "
         "else.\n\n## Interviews\n\nMost questions tied back to fundamentals and "
         "projects on my resume. Be ready to explain everything you claim.",
         True, False),
        ("New Publication from the Catalysis Group",
         ArticleKind.NEWS, ArticleCategory.RESEARCH,
         "A recent paper explores low-temperature reaction pathways.",
         "## Research highlight\n\nThe catalysis group has published new findings on "
         "low-temperature reaction pathways with promising energy implications. The "
         "full paper is available in the Publications section.",
         True, False),
    ]
    rows: list[Article] = []
    for i, (title, kind, cat, excerpt, body, published, featured) in enumerate(drafts):
        rows.append(Article(
            title=title, slug=unique_slug(title), kind=kind, category=cat,
            excerpt=excerpt, body=body, tags=["chea", kind],
            reading_minutes=estimate_reading_minutes(body),
            is_published=published, is_featured=featured,
            view_count=40 - i * 3, author_id=author_id,
            published_at=days(-(i + 1)),
        ))
    return rows


def opportunity_rows() -> list[Opportunity]:
    return [
        Opportunity(
            type=OpportunityType.INTERNSHIP, company="Reliance Industries",
            role="Process Engineering Intern", location="Jamnagar, Gujarat",
            description="A summer internship on refinery process optimization.",
            eligibility="Third-year B.Tech students in good standing.",
            required_skills=["Aspen Plus", "Mass & Energy Balances", "Python"],
            compensation="₹35,000 / month stipend",
            apply_url="https://example.com/apply/ril-intern", deadline=days(21),
            applicant_count=12, is_active=True,
        ),
        Opportunity(
            type=OpportunityType.PLACEMENT, company="Pidilite Industries",
            role="Graduate Process Engineer", location="Mumbai, Maharashtra",
            description="Full-time role in adhesives manufacturing and scale-up.",
            eligibility="Final-year students graduating this year.",
            required_skills=["Process Design", "Six Sigma", "Communication"],
            compensation="₹9.5 LPA", apply_url="https://example.com/apply/pidilite",
            deadline=days(35), applicant_count=28, is_active=True,
        ),
        Opportunity(
            type=OpportunityType.RESEARCH, company="IIT Bombay – Energy Lab",
            role="Research Assistant (Electrocatalysis)", location="Powai, Mumbai",
            description="Assist an ongoing project on hydrogen evolution catalysts.",
            eligibility="Students with a strong electrochemistry background.",
            required_skills=["Electrochemistry", "Lab Techniques", "MATLAB"],
            compensation="₹20,000 / month", apply_url="https://example.com/apply/iitb",
            deadline=days(14), applicant_count=7, is_active=True,
        ),
        Opportunity(
            type=OpportunityType.PROJECT, company="CHEA Student Projects",
            role="Open-Source Plant Simulator Contributor", location="Remote",
            is_remote=True,
            description="Contribute to a student-built flowsheet simulation tool.",
            eligibility="Anyone comfortable with Python and basic thermodynamics.",
            required_skills=["Python", "NumPy", "Git"], compensation="Unpaid / credit",
            apply_url="https://example.com/apply/sim", deadline=days(60),
            applicant_count=4, is_active=True,
        ),
        Opportunity(
            type=OpportunityType.SCHOLARSHIP, company="Alumni Association",
            role="Merit-cum-Means Scholarship", location="On-campus",
            description="Financial support for academically strong students.",
            eligibility="CGPA above 8.0 with demonstrated financial need.",
            required_skills=[], compensation="₹50,000 / year",
            apply_url="https://example.com/apply/scholarship", deadline=days(45),
            applicant_count=33, is_active=True,
        ),
    ]


async def seed_events(db) -> None:
    industrial = Event(
        title="Industrial Visit: Tata Chemicals", slug=unique_slug("Industrial Visit Tata Chemicals"),
        type=EventType.INDUSTRIAL_VISIT,
        description="A full-day visit to a soda ash manufacturing facility with a "
                    "guided plant walkthrough and a safety briefing.",
        venue="Tata Chemicals, Mithapur", starts_at=days(18),
        ends_at=days(18) + dt.timedelta(hours=8), registration_open=True, capacity=60,
        registered_count=22,
    )
    workshop = Event(
        title="Hands-on Aspen Plus Workshop", slug=unique_slug("Hands-on Aspen Plus Workshop"),
        type=EventType.WORKSHOP,
        description="A practical two-session workshop building and converging a "
                    "distillation flowsheet from scratch.",
        venue="Simulation Lab, ChE Block", starts_at=days(9),
        ends_at=days(9) + dt.timedelta(hours=4), registration_open=True, capacity=40,
        registered_count=31,
    )
    past_lecture = Event(
        title="Guest Lecture: Careers in Energy", slug=unique_slug("Guest Lecture Careers in Energy"),
        type=EventType.GUEST_LECTURE,
        description="An alumnus working in renewable energy shared career pathways "
                    "and answered student questions.",
        venue="Seminar Hall A", starts_at=days(-12),
        ends_at=days(-12) + dt.timedelta(hours=2), registration_open=False,
        registered_count=85,
    )
    db.add_all([industrial, workshop, past_lecture])
    await db.flush()

    db.add_all([
        EventScheduleItem(event_id=workshop.id, title="Session 1: Flowsheet basics",
                          description="Setting up components and a simple column.",
                          starts_at=workshop.starts_at),
        EventScheduleItem(event_id=workshop.id, title="Session 2: Convergence & analysis",
                          description="Tuning specs and reading results.",
                          starts_at=workshop.starts_at + dt.timedelta(hours=2)),
    ])
    db.add_all([
        EventGalleryImage(event_id=past_lecture.id,
                          image_url="https://picsum.photos/seed/chea-lecture-1/800/500",
                          caption="Audience during the talk"),
        EventGalleryImage(event_id=past_lecture.id,
                          image_url="https://picsum.photos/seed/chea-lecture-2/800/500",
                          caption="Q&A session"),
    ])


def publication_rows() -> list[Publication]:
    return [
        Publication(title="CHEA Annual Magazine 2024-25", type=PublicationType.MAGAZINE,
                    academic_year="2024-25",
                    description="The flagship yearly magazine featuring student work.",
                    cover_image_url="https://picsum.photos/seed/mag2425/600/800",
                    pdf_url="https://example.com/pubs/magazine-2024-25.pdf",
                    is_published=True, download_count=210, published_at=days(-30)),
        Publication(title="CHEA Gazette — Spring Edition", type=PublicationType.GAZETTE,
                    academic_year="2024-25",
                    description="Departmental news and updates for the spring term.",
                    cover_image_url="https://picsum.photos/seed/gazette-spring/600/800",
                    pdf_url="https://example.com/pubs/gazette-spring.pdf",
                    is_published=True, download_count=98, published_at=days(-20)),
        Publication(title="Annual Report 2023-24", type=PublicationType.ANNUAL_REPORT,
                    academic_year="2023-24",
                    description="A summary of departmental activities and outcomes.",
                    pdf_url="https://example.com/pubs/annual-report-2023-24.pdf",
                    is_published=True, download_count=64, published_at=days(-200)),
    ]


def resource_rows() -> list[Resource]:
    return [
        Resource(title="Heat Transfer — Complete Notes", type=ResourceType.NOTES,
                 description="Comprehensive notes covering conduction to heat exchangers.",
                 subject="Heat Transfer", semester=5, tags=["core", "notes"],
                 file_url="https://example.com/files/heat-transfer-notes.pdf",
                 file_size_kb=2400, download_count=156, is_active=True),
        Resource(title="Previous Year Papers — Thermodynamics", type=ResourceType.PREVIOUS_YEAR_PAPER,
                 description="Five years of solved end-semester papers.",
                 subject="Thermodynamics", semester=3, tags=["pyq"],
                 file_url="https://example.com/files/thermo-pyq.pdf",
                 file_size_kb=1800, download_count=243, is_active=True),
        Resource(title="DWSIM Open-Source Simulator", type=ResourceType.SOFTWARE,
                 description="A free chemical process simulator for coursework.",
                 subject="Process Simulation", tags=["software", "free"],
                 external_url="https://dwsim.org", download_count=77, is_active=True),
        Resource(title="Perry's Chemical Engineers' Handbook (Reference)",
                 type=ResourceType.BOOK,
                 description="The standard reference handbook — library access link.",
                 subject="Reference", tags=["book", "reference"],
                 external_url="https://example.com/library/perrys",
                 download_count=120, is_active=True),
        Resource(title="Placement Prep — Core Question Bank",
                 type=ResourceType.PLACEMENT_REPOSITORY,
                 description="Curated core and HR questions from past drives.",
                 subject="Placements", tags=["placement"],
                 file_url="https://example.com/files/placement-bank.pdf",
                 file_size_kb=900, download_count=312, is_active=True),
    ]


async def main() -> None:
    async with AsyncSessionLocal() as db:
        existing = await db.scalar(select(func.count()).select_from(Faculty))
        if existing:
            print(f"Database already seeded ({existing} faculty rows present). Skipping.")
            return

        admin = await seed_superuser(db)
        db.add_all(faculty_rows())
        db.add_all(contact_rows())
        db.add_all(article_rows(admin.id))
        db.add_all(opportunity_rows())
        await seed_events(db)
        db.add_all(publication_rows())
        db.add_all(resource_rows())
        await db.commit()
        print("Seed complete:")
        print("  - 1 super admin:", settings.FIRST_SUPERUSER_EMAIL)
        print("  - 4 faculty, 4 contacts")
        print("  - 5 articles (news + blogs)")
        print("  - 5 opportunities, 3 events, 3 publications, 5 resources")


if __name__ == "__main__":
    asyncio.run(main())
