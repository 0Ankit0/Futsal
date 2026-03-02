# API Endpoints

All endpoints are prefixed with `/api/v1`. The backend runs on `http://localhost:8000` by default.

**Authentication:** Most endpoints require `Authorization: Bearer <access_token>`. Obtain a token from `POST /api/v1/auth/login/`.

**Legend:**
- 🔓 Public — no authentication required
- 🔑 Authenticated — any logged-in user
- 👤 Owner — ground owner with active subscription
- 🛡️ Admin — superuser only

---

## Auth (`/api/v1/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/signup/` | 🔓 | Register a new account |
| POST | `/auth/login/` | 🔓 | Obtain JWT access + refresh tokens |
| POST | `/auth/refresh/` | 🔓 | Refresh access token |
| POST | `/auth/logout/` | 🔑 | Revoke refresh token |
| POST | `/auth/verify-email/` | 🔓 | Confirm email address |
| POST | `/auth/resend-verification/` | 🔓 | Resend email confirmation |
| POST | `/auth/password-reset-request/` | 🔓 | Request password reset email |
| POST | `/auth/password-reset-confirm/` | 🔓 | Confirm password reset |
| POST | `/auth/change-password/` | 🔑 | Change password (authenticated) |
| GET | `/auth/social/{provider}/` | 🔓 | Initiate OAuth (google/github/facebook) |
| GET | `/auth/social/{provider}/callback` | 🔓 | OAuth callback handler |
| POST | `/auth/otp/enable/` | 🔑 | Enable TOTP 2FA |
| POST | `/auth/otp/verify/` | 🔑 | Verify TOTP code |
| POST | `/auth/otp/validate/` | 🔑 | Validate TOTP during login |
| POST | `/auth/otp/disable/` | 🔑 | Disable TOTP 2FA |

---

## Users (`/api/v1/users`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/users/` | 🛡️ | List all users (paginated) |
| GET | `/users/me` | 🔑 | Get current user profile |
| PATCH | `/users/me` | 🔑 | Update current user profile |
| POST | `/users/me/avatar` | 🔑 | Upload profile avatar |
| GET | `/users/{user_id}` | 🛡️ | Get user by ID |
| PATCH | `/users/{user_id}` | 🛡️ | Update user by ID |
| DELETE | `/users/{user_id}` | 🛡️ | Delete user |
| GET | `/users/{user_id}/roles` | 🛡️ | List user's roles |
| POST | `/users/assign-role` | 🛡️ | Assign role to user |
| DELETE | `/users/remove-role` | 🛡️ | Remove role from user |

---

## Roles & Permissions (`/api/v1/roles`, `/api/v1/permissions`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/roles` | 🛡️ | List all roles |
| POST | `/roles` | 🛡️ | Create role |
| GET | `/roles/{role_id}` | 🛡️ | Get role detail |
| GET | `/roles/{role_id}/permissions` | 🛡️ | List role permissions |
| POST | `/roles/assign-permission` | 🛡️ | Assign permission to role |
| DELETE | `/roles/remove-permission` | 🛡️ | Remove permission from role |
| GET | `/permissions` | 🛡️ | List all permissions |
| POST | `/permissions` | 🛡️ | Create permission |
| GET | `/casbin/permissions/{user_id}` | 🛡️ | Get Casbin permissions for user |
| GET | `/casbin/roles/{user_id}` | 🛡️ | Get Casbin roles for user |
| GET | `/check-permission/{user_id}` | 🛡️ | Check specific permission |

---

## Tokens (`/api/v1/tokens`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/tokens/` | 🔑 | List active sessions/tokens |
| POST | `/tokens/revoke/{token_id}` | 🔑 | Revoke a specific token |
| POST | `/tokens/revoke-all` | 🔑 | Revoke all tokens (sign out everywhere) |

---

## Futsal Grounds (`/api/v1/futsal/grounds`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/futsal/grounds` | 🔓 | List all verified grounds (filterable by name, location, type, price) |
| POST | `/futsal/grounds` | 👤 | Create a new ground |
| GET | `/futsal/grounds/{ground_id}` | 🔓 | Get ground detail with images, reviews, rating |
| PUT | `/futsal/grounds/{ground_id}` | 👤 | Update ground info |
| DELETE | `/futsal/grounds/{ground_id}` | 👤 | Delete ground |
| GET | `/futsal/grounds/{ground_id}/slots` | 🔓 | Get available time slots for a date |
| GET | `/futsal/grounds/{ground_id}/bookings` | 👤 | List all bookings for this ground |
| GET | `/futsal/grounds/{ground_id}/images` | 🔓 | List ground images |
| POST | `/futsal/grounds/{ground_id}/images` | 👤 | Upload ground image |
| DELETE | `/futsal/grounds/{ground_id}/images/{image_id}` | 👤 | Delete ground image |
| POST | `/futsal/grounds/{ground_id}/closures` | 👤 | Add ground closure period |
| DELETE | `/futsal/grounds/{ground_id}/closures/{closure_id}` | 👤 | Remove closure period |
| POST | `/futsal/grounds/{ground_id}/verify` | 🛡️ | Verify / unverify a ground |
| GET | `/futsal/grounds/{ground_id}/reviews` | 🔓 | List reviews for this ground |
| POST | `/futsal/grounds/{ground_id}/reviews` | 🔑 | Submit a review |

---

## Bookings (`/api/v1/futsal/bookings`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/futsal/bookings` | 🔑 | List current user's bookings |
| POST | `/futsal/bookings` | 🔑 | Create booking (acquires slot lock, prevents double-booking) |
| GET | `/futsal/bookings/{booking_id}` | 🔑 | Get booking detail |
| PATCH | `/futsal/bookings/{booking_id}/cancel` | 🔑 | Cancel booking (2-hr grace window for users) |
| POST | `/futsal/bookings/{booking_id}/checkin` | 👤 | QR check-in (owner/manager/staff) |
| GET | `/futsal/bookings/{booking_id}/qr` | 🔑 | Get time-limited QR code |

---

## Reviews (`/api/v1/futsal/reviews`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| PUT | `/futsal/reviews/{review_id}` | 🔑 | Update own review |
| DELETE | `/futsal/reviews/{review_id}` | 🔑 | Delete own review |
| POST | `/futsal/reviews/{review_id}/reply` | 👤 | Owner reply to a review |

---

## Favourites (`/api/v1/futsal/favourites`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/futsal/favourites` | 🔑 | List user's favourite grounds |
| POST | `/futsal/favourites/{ground_id}` | 🔑 | Toggle favourite (add/remove) |

---

## Loyalty (`/api/v1/futsal/loyalty`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/futsal/loyalty` | 🔑 | Get loyalty account balance & tier |
| GET | `/futsal/loyalty/history` | 🔑 | Transaction history for loyalty points |

---

## Waitlist (`/api/v1/futsal/waitlist`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/futsal/waitlist` | 🔑 | Join waitlist for a fully-booked slot |
| DELETE | `/futsal/waitlist/{entry_id}` | 🔑 | Leave waitlist |

---

## Payments (`/api/v1/payments`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/payments/providers/` | 🔓 | List enabled payment gateways |
| POST | `/payments/initiate/` | 🔑 | Initiate payment (booking or subscription) |
| POST | `/payments/verify/` | 🔑 | Verify & confirm payment after gateway callback |
| GET | `/payments/` | 🔑 | List user's transactions |
| GET | `/payments/{transaction_id}/` | 🔑 | Get transaction detail |

---

## Payout Management (`/api/v1/payout-mgmt/payout`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/payout-mgmt/payout/gateway` | 👤 | Get owner's payment gateway config |
| POST | `/payout-mgmt/payout/gateway` | 👤 | Set payment gateway (credentials encrypted) |
| PUT | `/payout-mgmt/payout/gateway` | 👤 | Update gateway config |
| POST | `/payout-mgmt/payout/gateway/verify/{owner_id}` | 🛡️ | Mark gateway as verified |
| GET | `/payout-mgmt/payout/ledger` | 👤 | Owner's unsettled ledger entries |
| GET | `/payout-mgmt/payout/ledger` | 🛡️ | All ledger entries (admin) |
| GET | `/payout-mgmt/payout/pending-balance` | 👤 | Owner's pending payout amount |
| GET | `/payout-mgmt/payout/pending-balance` | 🛡️ | Platform-wide pending (admin) |
| GET | `/payout-mgmt/payout/history` | 👤 | Owner's payout history |
| GET | `/payout-mgmt/payout/history` | 🛡️ | All payout history (admin) |
| GET | `/payout-mgmt/payout/records` | 👤 / 🛡️ | Payout records (filterable by mode) |
| PATCH | `/payout-mgmt/payout/records/{record_id}/retry` | 🛡️ | Retry a failed payout |
| PATCH | `/payout-mgmt/payout/records/{record_id}/hold` | 🛡️ | Put payout on hold |
| GET | `/payout-mgmt/payout/mode` | 🛡️ | Get current payout mode (PLATFORM/DIRECT) |
| GET | `/payout-mgmt/payout/platform-balance` | 🛡️ | Platform's accumulated pending balance |

---

## Subscriptions (`/api/v1/subscriptions`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/subscriptions/plans` | 🔓 | List all subscription plans |
| POST | `/subscriptions/plans` | 🛡️ | Create subscription plan |
| PATCH | `/subscriptions/plans/{plan_id}` | 🛡️ | Update plan |
| POST | `/subscriptions/trial/{plan_id}` | 👤 | Start free trial |
| POST | `/subscriptions/verify-payment` | 👤 | Activate subscription after payment |
| GET | `/subscriptions/me` | 👤 | Get current owner's subscription |
| POST | `/subscriptions/cancel` | 👤 | Cancel subscription |
| GET | `/subscriptions/admin/all` | 🛡️ | List all owner subscriptions |
| PATCH | `/subscriptions/admin/{owner_id}/activate` | 🛡️ | Manually activate an owner's subscription |

---

## Ground Staff (`/api/v1/grounds`, `/api/v1/staff`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/grounds/{ground_id}/staff` | 👤 | List staff for a ground |
| POST | `/grounds/{ground_id}/staff/invite` | 👤 | Send staff invite by email |
| DELETE | `/grounds/{ground_id}/staff/{staff_id}` | 👤 | Remove staff member |
| POST | `/staff/accept-invite` | 🔓 | Accept staff invite (via token) |

---

## Notifications (`/api/v1/notifications`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/notifications/` | 🔑 | List notifications (paginated) |
| POST | `/notifications/` | 🛡️ | Send notification to user(s) |
| GET | `/notifications/{notification_id}/` | 🔑 | Get notification |
| DELETE | `/notifications/{notification_id}/` | 🔑 | Delete notification |
| PATCH | `/notifications/{notification_id}/read/` | 🔑 | Mark as read |
| PATCH | `/notifications/read-all/` | 🔑 | Mark all as read |
| GET | `/notifications/preferences/` | 🔑 | Get notification preferences |
| PATCH | `/notifications/preferences/` | 🔑 | Update preferences |
| PUT | `/notifications/preferences/push-subscription/` | 🔑 | Register push subscription |
| DELETE | `/notifications/preferences/push-subscription/` | 🔑 | Remove push subscription |

---

## Tenants (`/api/v1/tenants`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/tenants/` | 🔑 | List user's tenants |
| POST | `/tenants/` | 🔑 | Create tenant organisation |
| GET | `/tenants/{tenant_id}` | 🔑 | Get tenant detail |
| PATCH | `/tenants/{tenant_id}` | 🔑 | Update tenant |
| DELETE | `/tenants/{tenant_id}` | 🔑 | Delete tenant |
| GET | `/tenants/{tenant_id}/members` | 🔑 | List members |
| PATCH | `/tenants/{tenant_id}/members/{user_id}` | 🔑 | Update member role |
| DELETE | `/tenants/{tenant_id}/members/{user_id}` | 🔑 | Remove member |
| POST | `/tenants/{tenant_id}/invitations` | 🔑 | Send invitation |
| GET | `/tenants/{tenant_id}/invitations` | 🔑 | List pending invitations |
| DELETE | `/tenants/{tenant_id}/invitations/{invitation_id}` | 🔑 | Cancel invitation |
| POST | `/tenants/invitations/accept` | 🔑 | Accept invitation |

---

## WebSocket (`/api/v1/ws`)

| Path | Description |
|------|-------------|
| `GET /api/v1/ws/online/{user_id}/` | WebSocket connection for real-time presence |
| `GET /api/v1/ws/stats/` | Online user count and stats |

---

## Common Response Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No content |
| 400 | Bad request / validation error |
| 401 | Unauthenticated |
| 402 | Payment required (subscription expired) |
| 403 | Forbidden (insufficient permissions) |
| 404 | Not found |
| 409 | Conflict (e.g. slot already booked) |
| 422 | Unprocessable entity (schema validation) |
| 500 | Internal server error |

## Pagination

List endpoints accept:
- `page` — page number (default: 1)
- `page_size` — items per page (default: 20, max: 100)

Response envelopes return `{ items: [...], total: N, page: N, page_size: N, pages: N }`.

