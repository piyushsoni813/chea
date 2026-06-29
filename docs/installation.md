# Installation

Two ways to run the backend: with Docker (recommended — one command) or directly on your machine for active development.

## Prerequisites

- **Docker route:** Docker and the Docker Compose plugin.
- **Local route:** Python 3.12+ and PostgreSQL 16.

## Option A — Docker (recommended)

```bash
cp backend/.env.example .env
docker compose up --build
```

That starts three services — Postgres, the FastAPI backend, and NGINX. The backend's entrypoint waits for the database, runs `alembic upgrade head`, and seeds a starter dataset before serving.

Visit:

- http://localhost/docs — Swagger UI
- http://localhost:8000/docs — Swagger UI, bypassing NGINX
- http://localhost/health — health check

To stop: `docker compose down`. To wipe the database and start clean: `docker compose down -v` (this deletes the Postgres and uploads volumes).

The seeded super admin is `admin@chea.edu` / `admin12345`. Change these in `.env` before any real deployment.

## Option B — Local Python

Bring up Postgres however you prefer (local install, or just the compose service: `docker compose up db`).

```bash
cd backend
python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt

cp .env.example .env
# edit .env: set POSTGRES_HOST=localhost
```

Create the database if it doesn't exist, then migrate and seed:

```bash
createdb chea                       # or via psql / your tool of choice
export PYTHONPATH=.
alembic upgrade head
python -m scripts.seed
```

Run the API with autoreload:

```bash
uvicorn app.main:app --reload
```

The app also seeds the first super admin on startup, so even without running the seed script you can log in as `admin@chea.edu`.

## Running tests

```bash
cd backend
source .venv/bin/activate
export POSTGRES_HOST=localhost POSTGRES_PORT=5432 \
       POSTGRES_USER=chea POSTGRES_PASSWORD=chea POSTGRES_DB=chea_test
export PYTHONPATH=.
pytest
```

Use a separate database (`chea_test` above) — the suite creates and drops the full schema.

## Common issues

- **`alembic upgrade head` can't connect.** Check `POSTGRES_HOST`. Inside Docker it's `db`; locally it's `localhost`.
- **Push/email/Google features look inert.** That's expected until you set `FCM_CREDENTIALS_PATH`, the `SMTP_*` values, or `GOOGLE_CLIENT_ID`. Without them the app logs instead of sending, and `/auth/google` returns a clear "not configured" response.
- **Uploads 413 errors.** Raise `MAX_UPLOAD_MB` and the matching `client_max_body_size` in the NGINX config.
