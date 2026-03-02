# Project Structure

This document provides an overview of the repository's directory structure.

## Repository Root

```
Futsal/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml          # GitHub Actions CI/CD pipeline
├── Documentation/               # All project documentation
├── backend/                     # FastAPI application
├── frontend/                    # Next.js application
├── futsal_app/                  # Legacy .NET source (reference only)
├── README.md
└── DEPLOYMENT.md
```

## Backend (`backend/`)

```
backend/
├── src/
│   ├── main.py                  # FastAPI app factory; registers all routers
│   ├── db/
│   │   └── session.py           # SQLAlchemy async engine + init_db()
│   └── apps/
│       ├── core/                # Shared infrastructure
│       │   ├── config.py        # Pydantic Settings (reads .env)
│       │   ├── analytics.py     # PostHog server-side analytics singleton
│       │   ├── celery_app.py    # Celery + Beat schedule definition
│       │   ├── cache.py         # Redis client helpers
│       │   ├── security.py      # JWT, password hashing utilities
│       │   ├── middleware.py    # CORS, request ID middleware
│       │   └── tasks.py         # Shared Celery tasks
│       ├── iam/                 # Identity & Access Management
│       │   ├── models/          # User, Role, Token, IPAccess models
│       │   ├── api/             # /auth/*, /users/*, /roles/*, /tokens/* routes
│       │   └── services/        # Auth, user, social OAuth services
│       ├── futsal/              # Core futsal domain
│       │   ├── models/          # FutsalGround, Booking, BookingLock, Review,
│       │   │                    # GroundClosure, Favourite, LoyaltyAccount,
│       │   │                    # LoyaltyTransaction, Waitlist models
│       │   ├── api/             # grounds, bookings, reviews, favourites,
│       │   │                    # loyalty routes
│       │   └── services/        # booking_service (concurrency-safe),
│       │                        # slot_service, ground_service
│       ├── payout/              # Daily payout automation
│       │   ├── models/          # PayoutLedger, PayoutRecord, OwnerPaymentGateway
│       │   ├── api/             # gateway, ledger, records routes
│       │   └── services/        # payout_service (PLATFORM/DIRECT modes),
│       │                        # encryption (AES-256-GCM)
│       ├── subscription/        # Owner subscription & staff system
│       │   ├── models/          # SubscriptionPlan, OwnerSubscription, GroundStaff
│       │   ├── api/             # subscription plans, trial, payment verify,
│       │   │                    # cancel, staff invite/accept routes
│       │   ├── dependencies.py  # require_active_subscription,
│       │   │                    # require_ground_owner_or_manager guards
│       │   └── tasks.py         # Celery: daily status refresh, renewal reminders
│       ├── finance/             # Payment gateway integrations
│       │   ├── models/          # Transaction model
│       │   ├── api/             # /payments/* routes (initiate, verify)
│       │   └── services/        # khalti, esewa, stripe, paypal services
│       ├── notification/        # Push & in-app notifications
│       │   ├── models/          # Notification, NotificationPreference
│       │   └── api/             # /notifications/* routes
│       ├── multitenancy/        # Tenant/organisation system
│       │   ├── models/          # Tenant, TenantMember, TenantInvitation
│       │   └── api/             # /tenants/* routes
│       └── websocket/           # Real-time WebSocket
│           └── api/             # /ws/online/{user_id}, /ws/stats
├── alembic/
│   ├── env.py                   # Alembic environment (imports all models)
│   └── versions/                # Migration history (10 migrations)
├── .env.example                 # Environment variable template
├── pyproject.toml               # Python dependencies (uv / pip)
└── Dockerfile                   # Production container image
```

### Celery Beat Schedule

| Task | Schedule | Description |
|------|----------|-------------|
| `release_expired_locks` | every 5 min | Clears stale BookingLock rows |
| `update_completed_bookings` | every 5 min | Marks past bookings COMPLETED |
| `send_booking_reminders` | hourly | Sends booking reminder notifications |
| `daily_payout_task` | 00:00 UTC | Runs the daily payout job |
| `retry_failed_payouts` | every 4 hours | Retries FAILED payout records |
| `subscription-refresh-statuses` | 01:00 UTC | Updates subscription statuses (grace/expired) |
| `subscription-renewal-reminders` | 08:00 UTC | Emails owners 7 days before renewal |

---

## Frontend (`frontend/`)

```
frontend/
├── src/
│   ├── app/
│   │   ├── (public)/            # Unauthenticated pages
│   │   │   ├── page.tsx         # Landing page
│   │   │   ├── grounds/         # Browse grounds, ground detail, booking flow
│   │   │   └── booking/[id]/    # Booking confirmation
│   │   ├── (auth)/              # Login, signup, password reset, OTP
│   │   ├── (user-dashboard)/    # Authenticated player pages
│   │   │   ├── dashboard/       # Player dashboard
│   │   │   ├── my-bookings/     # Booking history & cancellation
│   │   │   ├── favourites/      # Saved grounds
│   │   │   ├── loyalty/         # Loyalty points & redemption
│   │   │   ├── notifications/   # Notification centre
│   │   │   └── settings/        # Profile settings
│   │   ├── (owner-dashboard)/   # Ground owner pages
│   │   │   └── owner/
│   │   │       ├── dashboard/   # KPI overview
│   │   │       ├── grounds/     # Ground listing & management
│   │   │       ├── bookings/    # Booking management
│   │   │       ├── payouts/     # Payout history & gateway config
│   │   │       ├── analytics/   # Revenue & booking charts
│   │   │       ├── reviews/     # Reviews management
│   │   │       ├── subscription/# Subscription status & upgrade
│   │   │       └── team/        # Staff invite & management
│   │   └── (admin-dashboard)/   # Superuser pages
│   │       └── admin/
│   │           ├── dashboard/   # Platform KPIs
│   │           ├── users/       # User management
│   │           ├── grounds/     # Ground verification & management
│   │           ├── payouts/     # Payout mode, records, platform balance
│   │           ├── subscriptions/# Owner subscription management
│   │           ├── tenants/     # Tenant management
│   │           └── rbac/        # Role & permission management
│   ├── components/
│   │   ├── analytics/           # PostHog provider & tracker
│   │   ├── layout/              # Sidebars, navbars, shells
│   │   └── owner/               # SubscriptionGate paywall component
│   ├── hooks/                   # React Query hooks (use-futsal, use-subscription,
│   │                            # use-analytics, use-auth, use-notifications, …)
│   ├── lib/
│   │   ├── api-client.ts        # Axios instance (base URL from env)
│   │   ├── posthog.ts           # PostHog client init
│   │   └── query-client.ts      # TanStack Query client
│   ├── store/
│   │   └── auth-store.ts        # Zustand auth store (persisted)
│   └── types/                   # TypeScript interfaces
├── .env.local                   # Frontend environment variables
├── next.config.ts               # Next.js config + PostHog reverse proxy
└── package.json
```

