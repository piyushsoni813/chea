# Architecture

The backend is a single FastAPI application organized in layers, so each concern has one home and the dependencies point in one direction: routers depend on services and schemas, services depend on models, models depend on the database core. Nothing reaches back upward.

## The layers

**Core** (`app/core`) holds configuration, security primitives, and logging. `config.py` is the only place that reads the environment; everything else imports `settings`. `security.py` owns password hashing (bcrypt) and JWT creation/verification.

**Database** (`app/db`) sets up the async SQLAlchemy engine and session factory and the declarative `Base` with two mixins every table reuses — UUID primary key and created/updated timestamps. Sessions are handed to routes through a dependency, never constructed ad hoc in handlers. PostgreSQL is the only data store.

**Models** (`app/models`) are the schema — plain SQLAlchemy 2.0 mapped classes. Enumerated fields are stored as strings rather than native Postgres enum types so that adding a new opportunity type or form kind never requires an `ALTER TYPE` migration. Validation of allowed values happens at the Pydantic layer. UUID keys everywhere keep IDs non-guessable and safe to expose.

**Schemas** (`app/schemas`) are the Pydantic v2 models that define request and response shapes. They're the contract the mobile app and dashboard code against. List and detail variants are explicit: a list item carries counts and personalisation flags; a detail adds the full body. Generic pagination is a single `Page[T]` used everywhere.

**Services** (`app/services`) hold logic that's more than a single query or that several routers share: token issuance and rotation, Google sign-in, push and email delivery, notification fan-out, bookmark/favorite toggles, and the resolver that turns saved references into display cards. Routers stay thin by leaning on these.

**API** (`app/api`) is dependencies plus the versioned routers. `deps.py` centralises the database session, the current-user resolution, role guards, and pagination, so a route declares what it needs by type annotation and gets it injected.

`main.py` assembles the app: configuration, CORS, friendly exception handlers, static file mounting for uploads, the startup hook that seeds the first super admin, and the inclusion of the versioned router under `/api/v1`.

## Notification flow

Push notifications follow a deliberate path through the system:

```
Admin (or system event)
  → FastAPI endpoint
    → PostgreSQL  (Notification row committed first — always persisted)
      → FastAPI BackgroundTasks
        → Firebase Cloud Messaging
          → Student device
```

The Notification row is written and committed before the response returns to the caller. FCM delivery is then dispatched as a FastAPI `BackgroundTask` — it runs in a worker thread after the response is sent, so FCM latency never affects API response time. Push is best-effort and fire-and-forget: FCM errors are logged and never propagated back to the caller. The stored row remains so the student sees the notification in-app even if push delivery fails.

When `FCM_CREDENTIALS_PATH` is not set, `send_push()` logs the intended delivery and returns — the rest of the flow is unchanged, making development without Firebase credentials seamless.

## Authentication and authorization

Registration is limited to configured email domains. A successful login returns a short-lived access token and a longer-lived refresh token. The access token carries the user id and role and is verified on every protected request without a database hit. The refresh token's identifier (`jti`) is recorded server-side, so refreshing rotates the token — the old one is marked revoked and the new one stored — and logout revokes all of a user's refresh tokens. That gives stateless reads with revocable sessions.

Authorization is role-based through dependency guards. A handler that needs an admin annotates its user parameter with the admin guard; the guard raises a 403 before the handler body runs. Role promotion is further restricted to super admins.

## Generic engagement

Rather than a bookmarks table per content type, one `(content_type, content_id)` pair lets a student save an article, a publication, a resource or an event through a single uniform mechanism. Favorites mirror it for opportunities. The cost is that listing saved items needs a resolver, since the rows only store references. `content_resolver.py` batches that lookup per type, so a mixed saved list resolves in a handful of queries rather than one per item. List endpoints annotate their items the same way, in bulk.

## Data access patterns

Everything is async end to end — asyncpg under SQLAlchemy's async engine. List endpoints paginate with a shared dependency and compute totals with a count over the filtered subquery. Relationships that a response needs are eager-loaded with `selectinload` to avoid N+1 queries.

## Background work

FastAPI's built-in `BackgroundTasks` handles all post-response work — currently FCM push delivery and, in the forms flow, the status-change notification. `BackgroundTasks` is injected into handlers that need it, passed through to the service layer, and the task is enqueued just before the handler returns. No external queue process, broker, or worker is required; the application is a single process with no runtime dependencies beyond Postgres.

For heavier scheduled work (deadline reminders, periodic aggregation) a task queue such as ARQ or Celery with a Postgres broker would be the natural next step, but nothing in the current feature set requires it.

## Migrations and tests

Alembic runs against the same async engine, with every model imported so autogenerate sees the whole schema. The test suite runs against a real Postgres — the array, JSONB and UUID columns rule out SQLite — and wraps each test in a transaction that rolls back afterwards. All async fixtures and tests share one event loop, because asyncpg connections are bound to the loop that created them.

## Why these choices

The theme is simplicity with room to grow. PostgreSQL as the sole data store means one fewer moving part to operate, monitor, and reason about. FastAPI `BackgroundTasks` is enough for push delivery without running a broker. String enums dodge a class of migrations. UUIDs avoid id-enumeration concerns. A generic engagement model means new content types get bookmarking for free. Server-side refresh tokens buy revocation without paying for stateful access tokens. Thin routers over real services keep the HTTP layer boring and the logic testable.
