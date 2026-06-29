# Environment variables

All configuration comes from the environment, loaded once in `app/core/config.py`. Copy `backend/.env.example` to `.env` and adjust. Defaults are chosen so a fresh clone boots without filling everything in. List values (CORS origins, email domains, upload extensions) are comma-separated.

## Core

| Variable | Default | Notes |
|---|---|---|
| `PROJECT_NAME` | `CHEA API` | Shown in Swagger. |
| `API_V1_PREFIX` | `/api/v1` | Base path for all endpoints. |
| `ENVIRONMENT` | `development` | `development` enables readable logs; anything else uses JSON logs. |
| `DEBUG` | `true` | Set `false` in production. |
| `SECRET_KEY` | dev placeholder | **Change in production.** Signs all JWTs. `openssl rand -hex 32`. |

## Auth / JWT

| Variable | Default | Notes |
|---|---|---|
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30` | Access-token lifetime. |
| `REFRESH_TOKEN_EXPIRE_DAYS` | `30` | Refresh-token lifetime. |
| `JWT_ALGORITHM` | `HS256` | Symmetric signing with `SECRET_KEY`. |
| `ALLOWED_EMAIL_DOMAINS` | `chea.edu,students.chea.edu` | Only these domains may self-register. |

## Database

| Variable | Default | Notes |
|---|---|---|
| `POSTGRES_HOST` | `localhost` | `db` inside Docker. |
| `POSTGRES_PORT` | `5432` | |
| `POSTGRES_USER` | `chea` | |
| `POSTGRES_PASSWORD` | `chea` | Change in production. |
| `POSTGRES_DB` | `chea` | Use a separate database for tests. |
| `DB_ECHO` | `false` | Logs SQL when `true` — noisy, handy for debugging. |

## CORS & uploads

| Variable | Default | Notes |
|---|---|---|
| `BACKEND_CORS_ORIGINS` | `*` | Restrict to real origins in production. |
| `UPLOAD_DIR` | `uploads` | Where files land; served under `/static/`. |
| `MAX_UPLOAD_MB` | `25` | Keep in step with NGINX `client_max_body_size`. |
| `ALLOWED_UPLOAD_EXTENSIONS` | `.pdf,.png,.jpg,.jpeg,.webp,.doc,.docx` | Allowed file types. |

## Email (SMTP)

Leave these blank to have the app log emails instead of sending them — useful in development.

| Variable | Default | Notes |
|---|---|---|
| `SMTP_HOST` | _(empty)_ | Set to enable real email. |
| `SMTP_PORT` | `587` | |
| `SMTP_USER` / `SMTP_PASSWORD` | _(empty)_ | Credentials. |
| `SMTP_FROM` | `noreply@chea.edu` | From address. |
| `SMTP_TLS` | `true` | |

## Integrations

| Variable | Default | Notes |
|---|---|---|
| `GOOGLE_CLIENT_ID` | _(empty)_ | Enables `/auth/google`; returns a clear "not configured" error until set. |
| `FCM_CREDENTIALS_PATH` | _(empty)_ | Path to a Firebase service-account JSON; enables push. Without it, pushes are logged. |

## Bootstrap & runtime

| Variable | Default | Notes |
|---|---|---|
| `FIRST_SUPERUSER_EMAIL` | `admin@chea.edu` | Seeded on startup. **Change it.** |
| `FIRST_SUPERUSER_PASSWORD` | `admin12345` | **Change it.** |
| `SEED_ON_START` | `true` | Container entrypoint runs the seed (idempotent). Set `false` after first prod boot. |
