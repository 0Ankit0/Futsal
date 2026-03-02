# Pages Overview

This document describes all frontend pages organised by user role / route group.

## Public Pages (`(public)/`)

Accessible without authentication.

| Page | Route | Description |
|------|-------|-------------|
| Landing | `/` | Hero section, platform stats, key features, how-it-works, CTA |
| Browse Grounds | `/grounds` | Filterable list of all verified grounds (search, ground type, price, location) |
| Ground Detail | `/grounds/[slug]` | Full ground info: images gallery, slot availability calendar, reviews, book button |
| Booking Form | `/grounds/[slug]/book` | Date + time slot picker, payment method selection, loyalty redemption option |
| Booking Confirmation | `/booking/[id]/confirmation` | Booking summary, QR code, add-to-calendar link |

---

## Auth Pages (`(auth)/`)

| Page | Route | Description |
|------|-------|-------------|
| Login | `/login` | Email + password login; social OAuth buttons (Google, GitHub, Facebook) |
| Sign Up | `/signup` | Registration form with email verification |
| Verify Email | `/verify-email` | Email confirmation link landing page |
| Password Reset | `/forgot-password` | Request reset email |
| Password Reset Confirm | `/reset-password` | Enter new password via reset link |
| IP Verify | `/ip-verify` | Verify login from a new IP address |
| OTP | `/otp` | TOTP code entry during 2FA login |

---

## Player Dashboard (`(user-dashboard)/`)

Requires authentication. Any logged-in user.

| Page | Route | Description |
|------|-------|-------------|
| Dashboard | `/dashboard` | Upcoming bookings, quick stats, recent activity |
| My Bookings | `/my-bookings` | Full booking history with status badges; cancel upcoming bookings |
| Favourites | `/favourites` | Saved grounds with quick-book shortcut |
| Loyalty | `/loyalty` | Points balance, tier progress, transaction history, redemption form |
| Notifications | `/notifications` | In-app notification centre; mark read, bulk clear |
| Settings | `/settings` | Profile info, password change, 2FA setup, notification preferences |

---

## Ground Owner Dashboard (`(owner-dashboard)/owner/`)

Requires authentication + active subscription. Shows `SubscriptionGate` paywall if subscription is expired.

| Page | Route | Description |
|------|-------|-------------|
| Dashboard | `/owner/dashboard` | KPIs: today's bookings, daily revenue, pending payout, active grounds |
| My Grounds | `/owner/grounds` | List of owner's grounds with status badges (verified/unverified) |
| Bookings | `/owner/bookings` | All bookings across owner's grounds; check-in button; filter by ground/date/status |
| Payouts | `/owner/payouts` | Payout history, ledger balance, payment gateway configuration form |
| Analytics | `/owner/analytics` | Revenue trends, booking heatmap, popular time slots, review scores |
| Reviews | `/owner/reviews` | All reviews across grounds; reply to review |
| Subscription | `/owner/subscription` | Current plan, expiry date, upgrade/renew, trial start |
| Team | `/owner/team` | Invite managers & staff by email; list active staff with roles; remove access |

---

## Superuser (Admin) Dashboard (`(admin-dashboard)/admin/`)

Requires `is_superuser = true`.

| Page | Route | Description |
|------|-------|-------------|
| Dashboard | `/admin/dashboard` | Platform KPIs: total users, grounds, bookings today, MRR, payout volume |
| Users | `/admin/users` | Full user list; edit roles; deactivate/delete accounts |
| Grounds | `/admin/grounds` | All grounds across all owners; verify/unverify; view owner details |
| Payouts | `/admin/payouts` | All payout records; switch payout mode (PLATFORM/DIRECT); view platform balance; retry/hold records |
| Subscriptions | `/admin/subscriptions` | All owner subscriptions; manually activate; view trial/grace states |
| RBAC | `/admin/rbac` | Role creation; permission assignment; per-role permission matrix |
| Tenants | `/admin/tenants` | Tenant organisations list; view members |
| Finance | `/admin/finances` | Transaction ledger across all payment providers |
| IP Access | `/admin/ip-access` | IP allowlist management |
| Tokens | `/admin/tokens` | Active session token list; revoke sessions |
| Notifications | `/admin/notifications` | Send broadcast notifications to users |

