# Convenience targets for the CHEA backend. Run from the repo root.
.PHONY: help up down logs build migrate seed test fmt revision shell

help:
	@echo "CHEA — common tasks"
	@echo "  make up         Start the full stack (db, redis, backend, nginx)"
	@echo "  make down       Stop the stack"
	@echo "  make logs       Tail backend logs"
	@echo "  make build      Rebuild the backend image"
	@echo "  make migrate    Apply DB migrations inside the backend container"
	@echo "  make seed       Seed the database inside the backend container"
	@echo "  make test       Run the backend test suite (needs a Postgres)"
	@echo "  make revision m=\"msg\"   Autogenerate a new Alembic migration"

up:
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f backend

build:
	docker compose build backend

migrate:
	docker compose exec backend alembic upgrade head

seed:
	docker compose exec backend python -m scripts.seed

revision:
	docker compose exec backend alembic revision --autogenerate -m "$(m)"

# Local (non-Docker) test run. Expects POSTGRES_* env vars to point at a
# throwaway database, e.g. POSTGRES_DB=chea_test.
test:
	cd backend && . .venv/bin/activate && pytest

fmt:
	cd backend && . .venv/bin/activate && python -m compileall -q app

shell:
	docker compose exec backend bash
