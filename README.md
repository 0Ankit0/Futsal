# FutsalApp

A full-stack futsal ground booking platform built with **FastAPI** (Python) and **Next.js** (TypeScript). Migrated from a .NET Aspire microservices architecture to a modern monorepo with a single-process backend.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Overview

FutsalApp lets players discover and book futsal grounds online, while ground owners manage their venues, track earnings, and receive automated daily payouts. A superuser (platform admin) oversees all grounds, subscriptions, and the financial flow.

**Three user roles:**
- **Superuser (Platform Admin)** — manages users, verifies grounds, controls payout mode, views platform-wide analytics
- **Ground Owner** — lists grounds, manages bookings, configures payment gateways, manages staff, pays monthly subscription
- **Player (User)** — browses grounds, books slots, earns loyalty points, leaves reviews

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Next.js 16 Frontend (TypeScript, Tailwind, shadcn/ui)  │
│  Public site · Owner dashboard · Admin dashboard        │
└──────────────────────┬──────────────────────────────────┘
                       │ REST + WebSocket
┌──────────────────────▼──────────────────────────────────┐
│  FastAPI Backend (Python 3.12)  ─  137 routes           │
│  IAM · Futsal · Payout · Subscription · Notifications   │
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
    ┌──────▼──────┐           ┌───────▼──────┐
    │  PostgreSQL │           │  Redis Cache │
    │  (SQLModel) │           │  + Celery    │
    └─────────────┘           └──────────────┘
```

### Payout Modes

| Mode       | Flow                                                          |
|------------|---------------------------------------------------------------|
| `PLATFORM` | Players pay → platform merchant account → midnight job pushes net to each owner's gateway |
| `DIRECT`   | Players pay → owner's own merchant account → midnight job records audit entry |

Switch by setting `PAYOUT_MODE=PLATFORM` or `PAYOUT_MODE=DIRECT` in `.env`. No code change required.

## Key Features

- **Concurrent booking prevention** — `SELECT FOR UPDATE` + `BookingLock` table (10-min TTL slot reservation)
- **Automated daily payouts** — Celery Beat at midnight; 3-retry exponential backoff on failure
- **Subscription system** — owners pay monthly; 3-day grace period; trial support
- **Ground staff / managers** — owners invite managers via email token; role-based access
- **Loyalty points** — 1 point per NPR 100 spent; redeemable on future bookings
- **Waitlist** — users join waiting list for fully-booked slots
- **QR check-in** — time-limited QR code per booking
- **PostHog analytics** — frontend page views + user identification; backend server-side events
- **Payment gateways** — Khalti, eSewa, Stripe, PayPal (owner credentials encrypted with AES-256-GCM)
- **WebSocket** — real-time online presence and slot availability updates
- **2FA / OTP** — TOTP-based two-factor authentication
- **Social login** — Google, GitHub, Facebook OAuth

## Tech Stack

| Layer     | Technology                                          |
|-----------|-----------------------------------------------------|
| Frontend  | Next.js 16, React 19, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query, Zustand |
| Backend   | FastAPI, SQLModel, Alembic, Pydantic v2              |
| Database  | PostgreSQL (production), SQLite (development)       |
| Cache     | Redis                                               |
| Queue     | Celery + Celery Beat                                |
| Auth      | JWT (access + refresh), 2FA TOTP, OAuth2            |
| Payments  | Khalti, eSewa, Stripe, PayPal                       |
| Analytics | PostHog (frontend + server-side)                    |
| Storage   | Local filesystem (dev), S3-compatible (production)  |

## Project Structure

```
Futsal/
├── backend/          # FastAPI application
├── frontend/         # Next.js application
├── Documentation/    # Architecture, API, and setup docs
└── futsal_app/       # Legacy .NET source (reference only)
```

See [Project Structure](./Documentation/Project-Structure.md) for a detailed breakdown.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/your-username/Futsal.git
cd Futsal

# 2. Backend
cd backend
cp .env.example .env          # fill in your values
uv venv && source .venv/bin/activate
uv pip install -e .
alembic upgrade head
uvicorn src.main:app --reload  # http://localhost:8000

# 3. Frontend (new terminal)
cd frontend
cp .env.local.example .env.local   # or edit .env.local
npm install
npm run dev                    # http://localhost:3000
```

See [Setup and Installation](./Documentation/Setup-and-Installation.md) for the full guide including Redis and Celery setup.

## Documentation

| Document | Description |
|----------|-------------|
| [Setup and Installation](./Documentation/Setup-and-Installation.md) | Local dev setup for backend, frontend, Redis, Celery |
| [Project Structure](./Documentation/Project-Structure.md) | Directory tree and module descriptions |
| [API Endpoints](./Documentation/API-Endpoints.md) | All 137 FastAPI routes with methods, auth requirements, and descriptions |
| [API Documentation](./Documentation/API-Documentation.md) | Request/response schemas and data models |
| [Pages Overview](./Documentation/Pages-Overview.md) | All frontend pages by dashboard/role |
| [Deployment](./Documentation/Deployment.md) | Docker Compose production deployment guide |

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push to your branch: `git push origin feature/your-feature`
5. Open a Pull Request

Please follow the existing coding conventions and ensure the backend imports cleanly before submitting.

## License

This project is licensed under the [MIT License](LICENSE).
