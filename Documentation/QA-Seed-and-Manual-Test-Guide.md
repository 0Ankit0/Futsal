# QA Seed and Manual Test Guide

This guide provides a reusable QA workflow for this repository, including deterministic seed data, manual test paths, endpoint checks, and known issues observed during the latest run.

## 1. Seed Data (Reusable)

Seed command:

```bash
cd backend
source .venv/bin/activate
python -m src.scripts.seed_qa_data
```

Seed script location:

- `backend/src/scripts/seed_qa_data.py`

This script is idempotent and prepares:

- 4 users (admin, owner, player, staff)
- owner subscription + plan
- verified ground + image
- bookings (confirmed, completed, cancelled)
- completed review + owner reply
- favourite + loyalty account + loyalty transaction
- payout gateway + payout record + payout ledger
- staff assignment and one notification

Seed credentials:

- `qa_admin` / `QaPass123`
- `qa_owner` / `QaPass123`
- `qa_player` / `QaPass123`
- `qa_staff` / `QaPass123`

## 2. Run Targets

Backend:

```bash
cd backend
source .venv/bin/activate
uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload
```

Frontend (web):

```bash
cd frontend
npm run dev -- --host 0.0.0.0 --port 3000
```

Flutter mobile app (web mode):

```bash
cd futsal_app
flutter run -d web-server --web-port 5050
```

## 3. Manual QA Workflow Checklist

### Public journey

1. Open `/`.
2. Go to `/grounds`.
3. Open `/grounds/qa-arena-kathmandu`.
4. Validate slot list and review rendering.
5. Select a slot and click `Book Now`.

### Player journey

1. Login with `qa_player`.
2. Validate `/dashboard` summary cards and notifications widget.
3. Validate `/my-bookings`.
4. Validate `/favourites`.
5. Validate `/loyalty`.
6. Validate `/notifications` and mark-as-read/clear actions.
7. Validate `/settings` and `/profile`.

### Owner journey

1. Login with `qa_owner`.
2. Validate `/owner/dashboard` KPIs.
3. Validate `/owner/grounds` and ground details.
4. Validate `/owner/bookings` date/ground filter.
5. Validate `/owner/reviews` and reply visibility.
6. Validate `/owner/payout` and `/owner/payout/settings`.
7. Validate `/owner/subscription`.
8. Validate `/owner/team`.

### Admin journey

1. Login with `qa_admin`.
2. Validate `/admin/dashboard`.
3. Validate `/admin/users`.
4. Validate `/admin/grounds`.
5. Validate `/admin/payouts`.
6. Validate `/admin/subscriptions`.
7. Validate `/admin/analytics`.

### Mobile web checks

1. Frontend web at `390x844` viewport for `/` and `/grounds`.
2. Flutter web build/run (`flutter run -d web-server --web-port 5050`).

## 4. Endpoint Smoke Coverage (Latest Run)

### Passed

- `GET /api/v1/futsal/grounds`
- `GET /api/v1/futsal/grounds/{id}`
- `GET /api/v1/futsal/grounds/{id}/slots?booking_date=YYYY-MM-DD`
- `GET /api/v1/users/me`
- `GET /api/v1/futsal/bookings`
- `GET /api/v1/futsal/loyalty`
- `GET /api/v1/futsal/favourites`
- `GET /api/v1/notifications/`
- `GET /api/v1/subscriptions/me`

### Issues observed

- Background `GET /api/v1/users/me` calls are very frequent during dashboard navigation (performance/noise risk).

## 5. Frontend Findings (Latest Run)

### Fixed in this run

- Admin dashboard runtime crash fixed by null-safe guards in:
  - `frontend/src/app/(admin-dashboard)/admin/dashboard/page.tsx`
- Owner subscription crash fixed:
  - backend enum normalization + response model conversion in `backend/src/apps/subscription/models/subscription.py` and `backend/src/apps/subscription/api/subscriptions.py`
  - frontend plan feature normalization in `frontend/src/hooks/use-subscription.ts`
- Player favourites crash fixed:
  - null-safe rendering and favourite-to-ground mapping in `frontend/src/app/(user-dashboard)/favourites/page.tsx`

### Remaining issues observed

1. Token revocation can still happen during rapid role switching/manual API logins in the same environment, causing temporary 401 redirects until re-login.
2. `owner/team` shows a 404 network resource in console during load (page still renders).
3. Loyalty history has one seed row rendered as `Invalid Date` due timestamp format in existing seed data.

## 6. Flutter Mobile Web Status (Latest Run)

Flutter web app did not compile, so runtime QA for `futsal_app` web is currently blocked.

Primary compile errors include:

- `lib/view/auth/data/repositories/auth_repository.dart`
- `lib/view/auth/register.dart`
- `lib/view/bookings/bookings.dart`
- `lib/view/home/map_view.dart`
- `lib/view/profile/profile.dart`
- `lib/view/edit_profile/edit_profile.dart`
- `lib/view/reviews/reviews.dart`
- `lib/view/settings/change_password.dart`
- `lib/view/reviews/bloc/reviews_bloc.dart`

Use this command to reproduce:

```bash
cd futsal_app
flutter run -d web-server --web-port 5050
```

## 7. Recommended Next QA Cycle

1. Optimize auth guard call frequency (reduce repeated `/users/me` calls) and re-run role-switch stress test.
2. Investigate the `owner/team` console 404 and seed loyalty timestamp formatting.
3. Fix Flutter compile errors and re-run mobile-web workflow.
4. Re-run this guide from section 1 for deterministic verification.
