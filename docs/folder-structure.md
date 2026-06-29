# Folder structure

A tour of the repository. The backend follows a layered layout where each directory is one responsibility.

```
chea/
├── docker-compose.yml          db + backend + nginx
├── Makefile                    common tasks (up, migrate, seed, test)
├── LICENSE                     MIT
├── README.md
├── .github/workflows/
│   └── backend-ci.yml          lint, apply migrations, run tests on Postgres
├── deploy/
│   └── nginx/
│       └── nginx.conf          reverse proxy + static file serving
├── docs/                       this documentation set
└── backend/
    ├── Dockerfile              multi-stage build, non-root runtime
    ├── entrypoint.sh           wait for DB, migrate, seed, then serve
    ├── requirements.txt        runtime dependencies
    ├── requirements-dev.txt    + pytest and test helpers
    ├── pytest.ini              async test configuration
    ├── alembic.ini             migration tool config
    ├── .env.example            documented environment template
    ├── alembic/
    │   ├── env.py              async-aware migration environment
    │   ├── script.py.mako      migration template
    │   └── versions/           generated migration files
    ├── scripts/
    │   └── seed.py             realistic starter dataset
    ├── tests/
    │   ├── conftest.py         transactional async client fixtures
    │   ├── test_auth.py
    │   └── test_content_and_engagement.py
    └── app/
        ├── main.py             app assembly: CORS, handlers, static, lifespan
        ├── core/
        │   ├── config.py       all settings, read from the environment
        │   ├── security.py     password hashing + JWT create/verify
        │   └── logging.py      dev/prod logging setup
        ├── db/
        │   ├── base.py         declarative Base + UUID/timestamp mixins
        │   ├── session.py      async engine, session, get_db dependency
        ├── models/             SQLAlchemy models — the database schema
        │   ├── enums.py        string-backed enumerations
        │   ├── user.py         User, StudentProfile, RefreshToken, DeviceToken
        │   ├── faculty.py      Faculty, Contact
        │   ├── content.py      Article, ArticleComment, ArticleLike
        │   ├── opportunity.py  Opportunity
        │   ├── event.py        Event + schedule, gallery, registrations
        │   ├── publication.py  Publication
        │   ├── resource.py     Resource
        │   ├── form.py         FormSubmission
        │   ├── notification.py Notification
        │   ├── engagement.py   Bookmark, Favorite (generic)
        │   └── upload.py       UploadedFile
        ├── schemas/            Pydantic request/response models (the API contract)
        │   ├── common.py       Message, pagination, generic Page[T]
        │   ├── auth.py · user.py · faculty.py · article.py
        │   ├── opportunity.py · event.py · publication.py · resource.py
        │   ├── form.py · notification.py · engagement.py
        │   ├── search.py · upload.py · admin.py
        ├── services/           logic shared across routers
        │   ├── auth_service.py        register, authenticate, token rotation
        │   ├── google_auth.py         Google sign-in
        │   ├── engagement_service.py  bookmark/favorite toggles + bulk lookups
        │   ├── content_resolver.py    saved references → display cards
        │   ├── notification_service.py create + push fan-out
        │   ├── push.py                Firebase Cloud Messaging (best effort)
        │   └── email.py               SMTP (logs when unconfigured)
        ├── utils/
        │   ├── slug.py                unique slug generation
        │   └── reading_time.py        reading-time estimate
        └── api/
            ├── deps.py                session, current user, role guards, paging
            └── v1/
                ├── __init__.py        mounts every router under /api/v1
                └── endpoints/
                    ├── auth.py · profile.py
                    ├── articles.py · opportunities.py · events.py
                    ├── publications.py · resources.py
                    ├── faculty.py · contacts.py
                    ├── forms.py · notifications.py
                    ├── bookmarks.py · favorites.py
                    ├── search.py · uploads.py · admin.py
```

## How a request flows

A request enters NGINX, which proxies it to the FastAPI app (or serves it directly if it's a `/static/` file). The matching router in `app/api/v1/endpoints` handles it, declaring what it needs — a database session, the current user, a role guard, pagination — as typed dependencies resolved by `app/api/deps.py`. The handler validates the body against a schema from `app/schemas`, calls into `app/services` for anything beyond a simple query, reads or writes through the `app/models` mapped classes, and returns a response model. Configuration for every layer comes from `app/core/config.py`.
