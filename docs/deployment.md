# Deployment

The compose stack is production-shaped but tuned for convenience. Before going live, tighten the items below.

## 1. Secrets and accounts

- Set a strong `SECRET_KEY` (`openssl rand -hex 32`). It signs every JWT — rotating it invalidates all existing tokens.
- Change `FIRST_SUPERUSER_EMAIL` and `FIRST_SUPERUSER_PASSWORD`, or create your admin out of band and remove the defaults.
- Use a managed Postgres or a backed-up volume; never rely on an unbacked container volume for real data.
- Keep `.env` and any Firebase service-account JSON out of version control (both are already gitignored).

## 2. Lock down exposure

In `docker-compose.yml` the `db` and `backend` services publish ports for convenience. In production, remove the `db` port mapping entirely and drop the direct `backend` `8000` mapping so traffic only enters through NGINX.

Set `ENVIRONMENT=production` and `DEBUG=false`, and replace the wildcard `BACKEND_CORS_ORIGINS=*` with your actual app and dashboard origins.

## 3. TLS

Terminate HTTPS at NGINX (or a load balancer in front of it). The simplest path is to add a certificate via your platform or Let's Encrypt and extend `deploy/nginx/nginx.conf` with a `listen 443 ssl;` server block that proxies to the same `chea_backend` upstream. Redirect `:80` to `:443`.

## 4. Migrations on deploy

The entrypoint runs `alembic upgrade head` on every start, so a rolling deploy applies new migrations automatically. For zero-downtime, keep migrations backward-compatible (add columns before you stop writing the old ones). To disable the automatic seed in production after the first run, set `SEED_ON_START=false`.

## 5. Scaling

The app is stateless apart from Postgres, so scale the backend horizontally:

```bash
docker compose up -d --scale backend=3
```

Put the replicas behind the existing NGINX upstream (add their addresses, or switch to a Docker/orchestrator service name). Session state lives in JWTs and the database, not in process memory, so any replica can serve any request. Refresh tokens are validated against the database, which keeps rotation and revocation correct across replicas.

## 6. File storage

Uploads are written to a shared volume and served by NGINX. For multi-host deployments, swap the local directory for object storage (S3 or compatible) behind the same `/static/` path, or mount shared network storage. The upload endpoint records each file in `uploaded_files`, so moving the storage backend doesn't change the API.

## 7. Observability

Logs go to stdout in JSON when `ENVIRONMENT` is not `development`, ready to ship to your aggregator. The `/health` endpoint is wired into the compose healthcheck; point your orchestrator's liveness probe at it too.

## Platform notes

Any host that runs Docker Compose works (a VPS is the simplest). For Kubernetes, the image is standard — translate the compose services into Deployments plus a managed Postgres, mount `.env` values as a Secret, and run the migration step as an init container or a Job.
