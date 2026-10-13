# Node + React + PostgreSQL — Production-Style Local Platform

A small full-stack app (React + Node.js/Express + PostgreSQL) taken step by
step into a production-style platform: containers, Kubernetes, an Ingress
API gateway, multi-environment CI/CD, platform services (Redis, queue, search,
read/write DB) and observability with autoscaling and rate limiting.

Everything runs **locally** (Docker + kind/minikube). Nothing here needs a cloud account.

## Contents

1. [Repository layout](#repository-layout)
2. [Prerequisites](#prerequisites)
3. [Task 1 — Docker Compose](#task-1--docker-compose)

---

## Repository layout

```
.
├── Dockerfile.backend            # multi-stage, non-root, tini
├── Dockerfile.frontend           # multi-stage, unprivileged nginx
├── .dockerignore
├── docker-compose.yml            # one-command local stack
├── .env.example                  # compose overrides (copy to .env)
├── backend/                      # Express API + BullMQ worker
├── frontend/                     # React (Vite) app + nginx.conf.template
├── k8s/                          # Kubernetes manifests (dev namespace)
├── observability/                # Prometheus, Grafana, Loki, Fluent Bit
├── .github/workflows/ci-cd.yml   # build → test → push → deploy
├── docs/                         # diagrams + evidence (screenshots)
└── README.md
```

## Prerequisites

| Tool | Needed for | Notes |
|---|---|---|
| Docker (Engine or Desktop) with Compose v2 | Task 1+ | `docker compose version` |
| `kubectl` | Task 2+ | |
| `kind` **or** `minikube` | Task 2+ | kind is what the helper scripts use |
| Node.js 20+ and npm | optional | only to run the backend/frontend outside Docker |

---

## Task 1 — Docker Compose

### Start (one command)

```bash
docker compose up --build
```

| What | URL |
|---|---|
| App (browser) | http://localhost:8080 |
| Backend API (direct, localhost only) | http://localhost:4000/api/health |
| PostgreSQL | not published to the host — `docker compose exec postgres psql -U appuser appdb` |

To override credentials or ports: `cp .env.example .env` and edit it. Stop with
`Ctrl+C`; `docker compose down` removes containers but **keeps the data**
(`docker compose down -v` also deletes the volume).

### What runs

```
browser ──► frontend (nginx :8080) ──/api/*──► backend (:4000) ──► postgres (:5432)
              edge network ───────────────────┘   └── data network (internal) ──┘
```

* **frontend** serves the Vite build and reverse-proxies `/api/*` to the
  backend, so the browser talks to a single origin.
* **backend** is the Express API. It creates its `items` table on boot and
  reads/writes Postgres.
* **postgres** stores data in the named volume `postgres_data`.

### Verify it works end to end

```bash
# 1. add an item through the frontend's origin (frontend -> backend -> postgres)
curl -s -X POST localhost:8080/api/items -H 'content-type: application/json' -d '{"name":"hello"}'
# 2. read it back
curl -s localhost:8080/api/items
# 3. prove persistence: recreate every container, data must still be there
docker compose down && docker compose up -d && curl -s localhost:8080/api/items
```

### Configuration (environment variables, no hard-coded secrets)

| Variable | Used by | Default (dev only) | Purpose |
|---|---|---|---|
| `DB_USER`, `DB_PASSWORD`, `DB_NAME` | postgres, backend | `appuser`, *dev placeholder*, `appdb` | database credentials |
| `DB_HOST`, `DB_PORT` | backend | `postgres`, `5432` | set in compose; the service name is the DNS name |
| `VITE_API_BASE_URL` | frontend (build arg) | `/api` | API base URL the browser uses |
| `BACKEND_URL` | frontend (runtime env) | `http://backend:4000` | where nginx proxies `/api/*` |
| `FRONTEND_PORT`, `BACKEND_PORT` | compose | `8080`, `4000` | published host ports |

Nothing secret is written into a Dockerfile or image layer. The `:-` defaults
in `docker-compose.yml` exist only so a bare `docker compose up` works on a
laptop; `.env` is git-ignored and excluded from build contexts, and Kubernetes /
CI inject credentials from Secrets (see Tasks 2 and 4).

### Dockerfile design notes

* **Multi-stage.** Backend: a `deps` stage runs `npm ci --omit=dev`, the runtime
  stage copies only `node_modules` + `src`. Frontend: a Node stage builds the
  bundle; the runtime image is just nginx + static files (no Node, no sources).
* **Layer caching.** `package*.json` are copied before the source, so a code
  change does not re-install dependencies. `npm` uses a BuildKit cache mount.
* **Small + safe base.** `node:20-alpine` and `nginx-unprivileged:alpine`; both
  containers run as non-root, backend uses `tini` as PID 1 for clean shutdowns.
* **One build context, two Dockerfiles.** The context is the repo root (so CI
  can use the same files); `.dockerignore` keeps it small and keeps `.env` out.
* **Same image, many roles.** The backend image also runs the queue worker
  (Task 5) with a different `command`.
* **Compose hardening.** `cap_drop: ALL`, `no-new-privileges`, healthchecks with
  `depends_on: condition: service_healthy`, and a split `edge`/`data` network:
  the frontend is not attached to the data network, which is `internal: true`.
