# CHEA

The official platform of the Chemical Engineering Students Association — a Flutter mobile app, a FastAPI backend, and an admin dashboard, built to be the department's central digital home.

This repository is being built backend-first. The API is what the mobile app and the admin dashboard both talk to, so it ships first and ships *runnable*: clone, copy one env file, and `docker compose up` gives you a live, documented, seeded API. The Flutter app and admin dashboard build on the contracts defined here.

> **Status.** The backend is complete and verified — 76 endpoints across 16 routers, 22 database tables under Alembic migration, a realistic seed dataset, and a passing test suite that runs against a real Postgres. The Flutter client and admin dashboard are the next milestones.

---

## What's here

```
chea/
├── backend/                 FastAPI service (this milestone)
│   ├── app/
│   │   ├── core/            config, security, logging
│   │   ├── db/              async engine, session
│   │   ├── models/          SQLAlchemy models (the schema)
│   │   ├── schemas/         Pydantic request/response models
│   │   ├── services/        auth, push, email, engagement, notifications
│   │   ├── api/             dependencies + versioned routers
│   │   └── main.py          app assembly, CORS, static, lifespan
│   ├── alembic/             migration environment + versions
│   ├── scripts/seed.py      starter dataset
│   ├── tests/               transactional pytest suite
│   └── Dockerfile
├── deploy/nginx/            reverse-proxy config
├── docs/                    install, deployment, architecture, API, schema
├── docker-compose.yml       db + backend + nginx
├── Makefile                 common tasks
└── .github/workflows/       CI (lint, migrate, test against Postgres)
```

A deeper tour of the layout lives in [`docs/folder-structure.md`](docs/folder-structure.md).

---

## Quick start (Docker)

```bash
git clone <your-fork-url> chea
cd chea
cp backend/.env.example .env          # defaults already line up with compose
docker compose up --build
```

On boot the backend waits for Postgres, applies migrations, and seeds a starter dataset. The stack is three services — Postgres, backend, and NGINX. Then:

- Swagger UI — http://localhost/docs (through NGINX) or http://localhost:8000/docs (direct)
- ReDoc — http://localhost/redoc
- Health — http://localhost/health

Sign in to the seeded super-admin account to exercise the admin endpoints:

```
email:    admin@chea.edu
password: admin12345
```

Change both in `.env` before deploying anywhere real.

Full setup notes, including running without Docker, are in [`docs/installation.md`](docs/installation.md). Production guidance — TLS, secrets, scaling — is in [`docs/deployment.md`](docs/deployment.md).

---

## What the backend does

A student opens the app and reads department news and student blogs, browses internships, placements, projects, research and scholarships, registers for events with a QR code, downloads notes and past papers, reads the magazine and gazette, looks up faculty and contacts, submits forms, and gets notified when something relevant lands. Each of those maps to a real, tested endpoint group:

- **Auth** — email + password registration restricted to allowed domains, login, Google sign-in, JWT access tokens, server-side refresh-token rotation, role-based access (student, faculty, admin, super admin).
- **Content** — a single article model serves both news and blogs, distinguished by `kind`, with categories, likes, threaded comments, bookmarks, reading-time estimates, and featured flags.
- **Opportunities** — five types with filtering, sorting (including by deadline), favorites and bookmarks.
- **Events** — upcoming/past scoping, schedules, galleries, QR-based registration and check-in, capacity limits.
- **Publications & Resources** — typed, year-aware, download-counted, bookmarkable.
- **Faculty & Contacts** — searchable directories grouped by role.
- **Forms** — submit any of seven form types with a JSON payload, track your own history, staff review with status changes that notify the submitter.
- **Notifications** — per-user and broadcast, with unread counts; broadcasts fan out to registered devices via FCM (and degrade to logging when push isn't configured).
- **Bookmarks & Favorites** — one generic mechanism over every content type, with a batch resolver that turns saved references into display cards in a few queries.
- **Search** — one query across articles, opportunities, events, publications, resources and faculty.
- **Uploads** — streamed to disk with extension and size validation; served by NGINX in production.
- **Admin** — dashboard analytics, user management, and role assignment (promotion gated to super admins).

The full endpoint reference is in [`docs/api.md`](docs/api.md); the live, always-accurate version is the Swagger UI. The data model is documented in [`docs/database-schema.md`](docs/database-schema.md) with an ER diagram in [`docs/er-diagram.md`](docs/er-diagram.md).

---

## Running the tests

The suite runs against a real Postgres (the models use array, JSONB and UUID columns), wrapping each test in a transaction that rolls back afterwards.

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt

# point at a throwaway database
export POSTGRES_HOST=localhost POSTGRES_PORT=5432 \
       POSTGRES_USER=chea POSTGRES_PASSWORD=chea POSTGRES_DB=chea_test
export PYTHONPATH=.
pytest
```

CI does the same on every push, including a check that migrations apply from scratch.

---

## Tech

FastAPI · async SQLAlchemy 2.0 · PostgreSQL · Alembic · Pydantic v2 · PyJWT · bcrypt · Firebase Admin (push) · FastAPI BackgroundTasks · Docker · NGINX · GitHub Actions.

The mobile app targets Flutter with Material 3, Riverpod, GoRouter, Dio, Freezed and secure storage; the admin dashboard will consume the same API. Both arrive in later milestones.

---

## License

MIT — see [`LICENSE`](LICENSE).
