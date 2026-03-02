# Setup and Installation

This guide explains how to set up and run FutsalApp locally.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Python | ≥ 3.12 | [python.org](https://python.org) |
| uv | latest | `pip install uv` — fast Python package manager |
| Node.js | ≥ 20 | [nodejs.org](https://nodejs.org) |
| Redis | ≥ 7 | `brew install redis` / `apt install redis-server` |
| Git | any | — |
| PostgreSQL | ≥ 15 | Optional for dev; SQLite used by default when `DEBUG=True` |

---

## 1. Clone the Repository

```bash
git clone https://github.com/your-username/Futsal.git
cd Futsal
```

---

## 2. Backend Setup

### 2.1 Create Virtual Environment and Install Dependencies

```bash
cd backend
uv venv                          # creates .venv/
source .venv/bin/activate        # Windows: .venv\Scripts\activate
uv pip install -e .              # installs all deps from pyproject.toml
```

### 2.2 Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your values. Minimum required for local development:

```env
SECRET_KEY=your-secret-key-change-this
DEBUG=True
DATABASE_URL=sqlite+aiosqlite:///./db.sqlite3

# Redis (required for Celery)
REDIS_URL=redis://localhost:6379/0

# Email (can use Mailtrap for dev)
EMAIL_HOST=smtp.mailtrap.io
EMAIL_PORT=587
EMAIL_HOST_USER=your-mailtrap-user
EMAIL_HOST_PASSWORD=your-mailtrap-pass
EMAIL_FROM=noreply@futsalapp.com

# Payout mode: PLATFORM or DIRECT
PAYOUT_MODE=PLATFORM
PLATFORM_FEE_PCT=5.0

# PostHog analytics (optional for dev)
POSTHOG_ENABLED=false
POSTHOG_API_KEY=
```

### 2.3 Run Database Migrations

```bash
alembic upgrade head
```

### 2.4 Start the Backend

```bash
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### 2.5 Start Celery Worker (separate terminal)

```bash
source .venv/bin/activate
celery -A src.apps.core.celery_app worker --loglevel=info
```

### 2.6 Start Celery Beat Scheduler (separate terminal)

```bash
source .venv/bin/activate
celery -A src.apps.core.celery_app beat --loglevel=info
```

> **Tip:** Use `pyproject.toml` scripts — `uv run celery-worker` and `uv run celery-beat` if configured.

---

## 3. Frontend Setup

### 3.1 Install Dependencies

```bash
cd ../frontend
npm install
```

### 3.2 Configure Environment

Edit `frontend/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_WS_URL=ws://localhost:8000

# PostHog (optional)
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
```

### 3.3 Start the Frontend

```bash
npm run dev
```

- App: http://localhost:3000

---

## 4. Create a Superuser

With the backend running, register a user via the API or frontend, then promote them:

```bash
# Using the FastAPI shell / script, or directly via psql/sqlite:
# Set is_superuser=True for your admin account
```

Or use the `/api/v1/auth/signup/` endpoint then update the user row in the database.

---

## 5. Running with Docker Compose (Recommended)

```bash
cd backend
docker compose up --build
```

This starts PostgreSQL, Redis, Celery worker, Celery Beat, and the FastAPI app together. See [Deployment](./Deployment.md) for the full production guide.

---

## 6. Environment Variables Reference

All backend variables are documented in `backend/.env.example`. Key sections:

| Section | Variables |
|---------|-----------|
| Core | `SECRET_KEY`, `DEBUG`, `DATABASE_URL`, `ALLOWED_HOSTS` |
| Redis | `REDIS_URL` |
| Email | `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` |
| Social OAuth | `GOOGLE_CLIENT_ID/SECRET`, `GITHUB_CLIENT_ID/SECRET`, `FACEBOOK_CLIENT_ID/SECRET` |
| Payments | `KHALTI_SECRET_KEY`, `ESEWA_MERCHANT_CODE`, `STRIPE_SECRET_KEY`, `PAYPAL_CLIENT_ID/SECRET` |
| Payout | `PAYOUT_MODE`, `PLATFORM_FEE_PCT`, `PLATFORM_KHALTI_*`, `PLATFORM_ESEWA_*`, `PLATFORM_BANK_*` |
| PostHog | `POSTHOG_ENABLED`, `POSTHOG_API_KEY`, `POSTHOG_HOST` |

---

## 7. Useful Commands

```bash
# Generate a new Alembic migration after model changes
alembic revision --autogenerate -m "describe your change"

# Apply latest migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Check current migration head
alembic current

# Format Python code
ruff format src/

# Type check frontend
cd frontend && npx tsc --noEmit
```

