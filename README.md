# FutsalApp

A full-stack futsal ground booking platform built with **FastAPI** and **Next.js**. The project is focused on the core booking experience: players can discover grounds, view live availability, reserve slots, and manage their bookings, while owners can manage their grounds and monitor reservations.

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

The app is intentionally centered on the workflows a futsal booking product needs most:

- **Players** can sign up, browse grounds, review slot availability, make bookings, and manage upcoming or past matches.
- **Ground owners** can create and update ground listings, set pricing and hours, and review bookings for each venue.

Non-core product branches such as loyalty rewards, subscriptions, payouts, admin analytics, and template-style dashboard features have been removed from the active app flow so the main journeys are reliable and easier to maintain.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Next.js 16 Frontend (TypeScript, Tailwind)             │
│  Public site · Player dashboard · Owner dashboard       │
└──────────────────────┬──────────────────────────────────┘
                       │ REST + WebSocket
┌──────────────────────▼──────────────────────────────────┐
│  FastAPI Backend                                         │
│  Auth · Grounds · Slots · Bookings · Reviews            │
└──────────┬──────────────────────────┬───────────────────┘
           │                          │
     ┌──────▼──────┐           ┌───────▼──────┐
     │  PostgreSQL │           │  Redis Cache │
     │  (SQLModel) │           │  / WebSocket │
     └─────────────┘           └──────────────┘
```

## Key Features

- **Ground discovery** — browse grounds with search, pricing, and type filters
- **Ground detail and slots** — inspect venue details and see live slot availability by date
- **Safe booking flow** — reserve a slot with race-condition-safe locking to prevent double bookings
- **Booking management** — view confirmed, completed, and cancelled bookings in one place
- **Owner tools** — create and edit grounds, set hours and pricing, and review venue bookings
- **Reviews** — display ground feedback from completed bookings
- **JWT authentication** — email/password auth with protected player and owner areas

## Tech Stack

| Layer     | Technology                                          |
|-----------|-----------------------------------------------------|
| Frontend  | Next.js 16, React 19, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query, Zustand |
| Backend   | FastAPI, SQLModel, Alembic, Pydantic v2             |
| Database  | PostgreSQL (production), SQLite (development)       |
| Cache     | Redis (optional for production cache/WebSocket integrations) |
| Queue     | Celery (optional background tasks)                  |
| Auth      | JWT (access + refresh)                              |
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

See [Setup and Installation](./Documentation/Setup-and-Installation.md) for the full guide. Redis and Celery are optional for the simplified booking-first local workflow.

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
