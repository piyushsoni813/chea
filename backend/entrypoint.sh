#!/usr/bin/env bash
# Wait for Postgres, run migrations, seed once, then exec the given command.
set -e

host="${POSTGRES_HOST:-db}"
port="${POSTGRES_PORT:-5432}"

echo "Waiting for Postgres at ${host}:${port} ..."
python - <<'PY'
import os, socket, time
host = os.getenv("POSTGRES_HOST", "db")
port = int(os.getenv("POSTGRES_PORT", "5432"))
for _ in range(60):
    try:
        with socket.create_connection((host, port), timeout=2):
            print("Postgres is reachable.")
            break
    except OSError:
        time.sleep(1)
else:
    raise SystemExit("Postgres did not become reachable in time.")
PY

echo "Running database migrations ..."
alembic upgrade head

if [ "${SEED_ON_START:-true}" = "true" ]; then
  echo "Seeding database (idempotent) ..."
  python -m scripts.seed || echo "Seed step skipped or already applied."
fi

echo "Starting: $*"
exec "$@"
