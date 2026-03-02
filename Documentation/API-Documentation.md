# API Documentation

Comprehensive request/response schemas and data models for the FutsalApp FastAPI backend.

## Table of Contents

- [Authentication](#authentication)
- [Key Request Schemas](#key-request-schemas)
- [Key Response Schemas](#key-response-schemas)
- [Database Models](#database-models)
- [Enums](#enums)
- [Error Format](#error-format)
- [Analytics Events](#analytics-events)

---

## Authentication

All protected endpoints require a Bearer token obtained from `POST /api/v1/auth/login/`.

```http
Authorization: Bearer <access_token>
```

Access tokens expire in 15 minutes. Use `POST /api/v1/auth/refresh/` with the refresh token to get a new access token.

---

## Key Request Schemas

### `SignupRequest`

```json
{
  "username": "string",
  "email": "user@example.com",
  "password": "string (min 8 chars)",
  "confirm_password": "string",
  "first_name": "string (optional)",
  "last_name": "string (optional)"
}
```

### `LoginRequest`

```json
{
  "username": "string (email or username)",
  "password": "string"
}
```

### `BookingCreate`

```json
{
  "ground_id": 1,
  "booking_date": "2025-03-15",
  "start_time": "10:00",
  "end_time": "11:00",
  "payment_method": "khalti",
  "notes": "string (optional)",
  "loyalty_points_to_redeem": 50
}
```

> Concurrency: the server acquires a `BookingLock` and uses `SELECT FOR UPDATE`. Returns `409 Conflict` if the slot is taken.

### `GroundCreate`

```json
{
  "name": "string",
  "description": "string",
  "address": "string",
  "city": "string",
  "latitude": 27.7172,
  "longitude": 85.3240,
  "ground_type": "FUTSAL_5",
  "price_per_hour": 1500.00,
  "open_time": "06:00",
  "close_time": "22:00",
  "slot_duration_minutes": 60,
  "max_advance_booking_days": 14,
  "amenities": ["parking", "changing_room", "floodlights"]
}
```

### `PaymentInitiate`

```json
{
  "amount": 1500,
  "currency": "NPR",
  "provider": "khalti",
  "context": "booking",
  "context_id": 42,
  "return_url": "https://futsalapp.com/booking/42/confirmation",
  "website_url": "https://futsalapp.com"
}
```

### `GatewaySetup` (owner payment gateway config)

```json
{
  "provider": "khalti",
  "credentials": {
    "secret_key": "live_secret_key_xxx",
    "public_key": "live_public_key_xxx"
  }
}
```

> Credentials are encrypted with AES-256-GCM before storage. Never returned in responses.

### `SubscriptionVerifyPayment`

```json
{
  "plan_id": 1,
  "transaction_id": 99
}
```

### `StaffInvite`

```json
{
  "email": "manager@example.com",
  "role": "manager"
}
```

### `ReviewCreate`

```json
{
  "rating": 4,
  "comment": "Great ground, well maintained!"
}
```

---

## Key Response Schemas

### `AuthTokens`

```json
{
  "access": "eyJ...",
  "refresh": "eyJ...",
  "token_type": "Bearer"
}
```

### `UserMe`

```json
{
  "id": "1",
  "username": "john_doe",
  "email": "john@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "is_active": true,
  "is_superuser": false,
  "is_confirmed": true,
  "otp_enabled": false,
  "otp_verified": false,
  "roles": ["owner"],
  "image_url": "https://..."
}
```

### `GroundDetail`

```json
{
  "id": 1,
  "name": "Sunrise Futsal",
  "slug": "sunrise-futsal",
  "description": "...",
  "address": "Lazimpat, Kathmandu",
  "city": "Kathmandu",
  "latitude": 27.7172,
  "longitude": 85.3240,
  "ground_type": "FUTSAL_5",
  "price_per_hour": 1500.00,
  "open_time": "06:00",
  "close_time": "22:00",
  "average_rating": 4.2,
  "review_count": 38,
  "is_verified": true,
  "is_active": true,
  "amenities": ["parking", "floodlights"],
  "images": [{ "id": 1, "url": "...", "is_primary": true }],
  "owner": { "id": "5", "username": "owner_name" },
  "created_at": "2024-01-01T00:00:00Z"
}
```

### `BookingDetail`

```json
{
  "id": 42,
  "ground_id": 1,
  "ground_name": "Sunrise Futsal",
  "user_id": "3",
  "booking_date": "2025-03-15",
  "start_time": "10:00",
  "end_time": "11:00",
  "total_amount": 1500.00,
  "status": "CONFIRMED",
  "payment_method": "khalti",
  "loyalty_points_earned": 15,
  "loyalty_points_redeemed": 0,
  "qr_code_url": "/api/v1/futsal/bookings/42/qr",
  "created_at": "2025-03-10T08:30:00Z",
  "cancelled_at": null,
  "cancellation_reason": null
}
```

### `SlotAvailability`

```json
{
  "date": "2025-03-15",
  "slots": [
    { "start_time": "06:00", "end_time": "07:00", "available": true, "locked": false },
    { "start_time": "07:00", "end_time": "08:00", "available": false, "locked": false },
    { "start_time": "08:00", "end_time": "09:00", "available": true, "locked": true }
  ]
}
```

### `PayoutRecord`

```json
{
  "id": 10,
  "owner_id": "5",
  "period_start": "2025-03-14",
  "period_end": "2025-03-14",
  "total_bookings": 8,
  "gross_amount": 12000.00,
  "platform_fee_pct": 5.0,
  "platform_fee": 600.00,
  "net_amount": 11400.00,
  "currency": "NPR",
  "status": "COMPLETED",
  "payout_mode": "PLATFORM",
  "provider": "khalti",
  "transaction_ref": "KHALTI-TXN-xxx",
  "initiated_at": "2025-03-15T00:00:00Z",
  "completed_at": "2025-03-15T00:01:23Z"
}
```

### `OwnerSubscription`

```json
{
  "id": 3,
  "owner_id": "5",
  "plan": { "id": 1, "name": "Standard", "price": 999.00, "trial_days": 14 },
  "status": "ACTIVE",
  "current_period_start": "2025-03-01",
  "current_period_end": "2025-03-31",
  "trial_ends_at": null,
  "cancel_at_period_end": false,
  "created_at": "2025-02-01T00:00:00Z"
}
```

### `LoyaltyAccount`

```json
{
  "id": 1,
  "user_id": "3",
  "balance": 250,
  "tier": "SILVER",
  "total_earned": 580,
  "total_redeemed": 330
}
```

### `PaginatedResponse<T>`

```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 20,
  "pages": 5
}
```

---

## Database Models

### Core IAM

| Model | Table | Key Fields |
|-------|-------|------------|
| User | `users` | id, username, email, is_superuser, otp_enabled, created_at |
| Role | `roles` | id, name |
| Permission | `permissions` | id, codename |
| RefreshToken | `refresh_tokens` | id, user_id, token, expires_at |
| UsedToken | `used_tokens` | token (blacklist) |
| IPAccessRule | `ip_access_rules` | cidr, action (ALLOW/DENY) |

### Futsal Domain

| Model | Table | Key Fields |
|-------|-------|------------|
| FutsalGround | `futsal_grounds` | id, owner_id, name, slug, ground_type, price_per_hour, is_verified |
| GroundImage | `ground_images` | id, ground_id, url, is_primary |
| GroundClosure | `ground_closures` | id, ground_id, start_date, end_date |
| Booking | `bookings` | id, ground_id, user_id, booking_date, start_time, end_time, status, total_amount |
| BookingLock | `booking_locks` | id, ground_id, booking_date, start_time, end_time, locked_by_booking_id, expires_at |
| Review | `reviews` | id, ground_id, user_id, rating, comment, owner_reply |
| Favourite | `favourites` | id, user_id, ground_id |
| LoyaltyAccount | `loyalty_accounts` | id, user_id, balance, tier |
| LoyaltyTransaction | `loyalty_transactions` | id, account_id, booking_id, points, type |
| Waitlist | `waitlist` | id, user_id, ground_id, booking_date, start_time |

### Payout

| Model | Table | Key Fields |
|-------|-------|------------|
| PayoutLedger | `payout_ledger` | id, ground_id, owner_id, booking_id, gross_amount, net_amount, settled, payout_mode |
| PayoutRecord | `payout_records` | id, owner_id, net_amount, status, payout_mode, provider, retry_count |
| OwnerPaymentGateway | `owner_payment_gateways` | id, owner_id, provider, credentials_encrypted, is_verified, is_active |

### Subscription

| Model | Table | Key Fields |
|-------|-------|------------|
| SubscriptionPlan | `subscription_plans` | id, name, price, trial_days, is_active |
| OwnerSubscription | `owner_subscriptions` | id, owner_id, plan_id, status, current_period_start/end, trial_ends_at |
| GroundStaff | `ground_staff` | id, ground_id, user_id, role, invite_token |

### Finance

| Model | Table | Key Fields |
|-------|-------|------------|
| Transaction | `transactions` | id, user_id, amount, currency, provider, status, reference |

### Notifications

| Model | Table | Key Fields |
|-------|-------|------------|
| Notification | `notifications` | id, user_id, title, body, type, is_read |
| NotificationPreference | `notification_preferences` | id, user_id, email_enabled, push_enabled, push_subscription |

---

## Enums

### `BookingStatus`
`PENDING` | `CONFIRMED` | `CANCELLED` | `COMPLETED`

### `GroundType`
`FUTSAL_5` | `FUTSAL_6` | `FUTSAL_7` | `FUTSAL_8`

### `PayoutStatus`
`PENDING` | `PROCESSING` | `COMPLETED` | `FAILED` | `ON_HOLD`

### `PayoutMode`
`PLATFORM` — platform collects money, pushes to owner at midnight
`DIRECT` — owner collects directly, midnight job records audit entry only

### `SubscriptionStatus`
`TRIALING` | `ACTIVE` | `GRACE` (expired ≤3 days ago) | `EXPIRED` | `CANCELLED` | `PAST_DUE`

### `StaffRole`
`MANAGER` | `STAFF`

### `GatewayProvider`
`KHALTI` | `ESEWA` | `BANK_TRANSFER`

### `LoyaltyTier`
`BRONZE` (0–499 pts) | `SILVER` (500–1999 pts) | `GOLD` (2000–4999 pts) | `PLATINUM` (5000+ pts)

---

## Error Format

All errors follow the RFC 7807 problem detail format:

```json
{
  "detail": "Human-readable error message",
  "code": "machine_readable_code"
}
```

Subscription guard raises:
```json
{
  "detail": "Active subscription required to perform this action.",
  "code": "subscription_required"
}
```

Slot conflict raises:
```json
{
  "detail": "This time slot is already booked.",
  "code": "slot_conflict"
}
```

---

## Analytics Events

### Frontend Events (PostHog JS)

| Event | Properties | Trigger |
|-------|------------|---------|
| `$pageview` | `$current_url` | Every route change |
| `user_signed_up` | `method` | Signup completion |
| `user_signed_in` | `method` | Login success |
| `ground_viewed` | `ground_id`, `ground_name` | Ground detail page |
| `ground_searched` | `query`, `filters`, `result_count` | Search query |
| `ground_favourited` | `ground_id`, `action` | Toggle favourite |
| `slot_selected` | `ground_id`, `date`, `start_time`, `price` | Slot selection |
| `booking_initiated` | `ground_id`, `amount`, `payment_method` | Booking form submit |
| `booking_confirmed` | `booking_id`, `ground_id`, `amount` | Payment verify success |
| `booking_cancelled` | `booking_id`, `reason` | Cancel button |
| `payment_initiated` | `amount`, `provider`, `context` | Payment drawer |
| `payment_success` | `amount`, `provider`, `transaction_id` | Verify callback |
| `trial_started` | `plan_id`, `plan_name`, `trial_days` | Trial start |
| `subscription_activated` | `plan_id`, `price` | Payment verified |
| `subscription_cancelled` | `plan_id`, `immediately` | Cancel form |
| `review_submitted` | `ground_id`, `rating` | Review form |
| `loyalty_points_redeemed` | `points`, `booking_id` | Booking with redemption |
| `staff_invited` | `ground_id`, `role` | Staff invite form |

### Backend Events (PostHog Python)

| Event | Properties | Trigger |
|-------|------------|---------|
| `booking_confirmed` | `booking_id`, `ground_id`, `amount`, `booking_date` | `confirm_booking()` after payment |
| `booking_cancelled` | `booking_id`, `ground_id`, `reason`, `cancelled_by_owner` | `cancel_booking()` |
| `subscription_activated` | `plan_id`, `transaction_id`, `period_end` | `activate_subscription()` |
| `payout_processed` | `payout_id`, `net_amount`, `mode`, `provider`, `bookings_count` | `_process_platform_payout()` on success |


## Table of Contents

- [Authentication Service (FutsalApi.Auth)](#authentication-service-futsalapi-auth)
  - [User Management](#user-management)
  - [Role Management](#role-management)
  - [User Role Management](#user-role-management)
- [Main API Service (FutsalApi.ApiService)](#main-api-service-futsalapi-apiservice)
  - [Booking Management](#booking-management)
  - [Futsal Ground Management](#futsal-ground-management)
  - [Payment Management](#payment-management)
  - [Payment Gateway Management](#payment-gateway-management)
  - [Review Management](#review-management)
  - [Notification Management](#notification-management)
- [Data Models](#data-models)
  - [Request Models](#request-models)
  - [Response Models](#response-models)
  - [Database Entities (DTOs)](#database-entities-dtos)

---

## Authentication Service (FutsalApi.Auth)

### User Management

Base URL: `/User`

#### Endpoints

| Method | Endpoint                   | Description               | Request Body                     | Response              |
| ------ | -------------------------- | ------------------------- | -------------------------------- | --------------------- |
| POST   | `/register`                | Register a new user       | `RegisterRequest`                | `Ok`                  |
| POST   | `/login`                   | Authenticate user         | `LoginRequest`                   | `AccessTokenResponse` |
| GET    | `/login/google`            | Google OAuth login        | -                                | Redirect to Google    |
| GET    | `/auth/google/callback`    | Handle Google callback    | -                                | Redirect              |
| POST   | `/logout`                  | Logout user               | -                                | `Ok`                  |
| POST   | `/refresh`                 | Refresh access token      | `RefreshRequest`                 | `AccessTokenResponse` |
| GET    | `/confirmEmail`            | Confirm email address     | Query params                     | `Ok`                  |
| POST   | `/resendConfirmationEmail` | Resend confirmation email | `ResendConfirmationEmailRequest` | `Ok`                  |
| POST   | `/forgotPassword`          | Request password reset    | `ForgotPasswordRequest`          | `Ok`                  |
| POST   | `/resetPassword`           | Reset password            | `ResetPasswordRequest`           | `Ok`                  |
| POST   | `/verifyResetCode`         | Verify reset code         | `VerifyResetCodeRequest`         | `Ok`                  |

#### Account Management

Base URL: `/User/manage`

| Method | Endpoint               | Description              | Request Body       | Response                 |
| ------ | ---------------------- | ------------------------ | ------------------ | ------------------------ |
| POST   | `/deactivate`          | Deactivate user account  | -                  | `Ok`                     |
| POST   | `/sendRevalidateEmail` | Send revalidation email  | -                  | `Ok`                     |
| GET    | `/revalidate`          | Revalidate user via link | Query params       | `Ok`                     |
| GET    | `/setup2fa`            | Setup 2FA                | -                  | `TwoFactorSetupResponse` |
| POST   | `/2fa`                 | Enable/disable 2FA       | `TwoFactorRequest` | `Ok`                     |
| GET    | `/info`                | Get user information     | -                  | `UserInfo`               |
| POST   | `/info`                | Update user information  | `UserInfo`         | `Ok`                     |

---

### Role Management

Base URL: `/Roles`
**Authorization Required**

#### Endpoints

| Method | Endpoint           | Description          | Request Body  | Response             |
| ------ | ------------------ | -------------------- | ------------- | -------------------- |
| GET    | `/`                | Get all roles        | -             | `IEnumerable<Role>`  |
| GET    | `/{roleId}`        | Get role by ID       | -             | `Role`               |
| POST   | `/`                | Create new role      | `RoleRequest` | `Role`               |
| PUT    | `/{roleId}`        | Update existing role | `RoleRequest` | `Role`               |
| DELETE | `/{roleId}`        | Delete role          | -             | `Ok`                 |
| GET    | `/{roleId}/Claims` | Get role claims      | -             | `IEnumerable<Claim>` |
| POST   | `/{roleId}/Claims` | Add role claim       | `ClaimModel`  | `Ok`                 |
| PUT    | `/{roleId}/Claims` | Update role claim    | `ClaimModel`  | `Ok`                 |
| DELETE | `/{roleId}/Claims` | Remove role claim    | `ClaimModel`  | `Ok`                 |

---

### User Role Management

Base URL: `/UserRoles`
**Authorization Required**

#### Endpoints

| Method | Endpoint         | Description                 | Request Body      | Response         |
| ------ | ---------------- | --------------------------- | ----------------- | ---------------- |
| GET    | `/`              | Get all user roles          | -                 | `List<UserRole>` |
| GET    | `/{userId}`      | Get roles for specific user | -                 | `List<string>`   |
| GET    | `/Role/{roleId}` | Get users in specific role  | -                 | `List<string>`   |
| POST   | `/`              | Assign role to user         | `UserRoleRequest` | `Ok`             |
| DELETE | `/{userId}`      | Remove user role            | Query: roleId     | `Ok`             |

---

## Main API Service (FutsalApi.ApiService)

### Booking Management

Base URL: `/Booking`
**Authorization Required**

#### Endpoints

| Method | Endpoint       | Description             | Request Body     | Response                       | Permissions     |
| ------ | -------------- | ----------------------- | ---------------- | ------------------------------ | --------------- |
| GET    | `/`            | Get bookings by user ID | -                | `IEnumerable<BookingResponse>` | CanView:Booking |
| POST   | `/`            | Create new booking      | `BookingRequest` | `string`                       | -               |
| PUT    | `/{id}`        | Update existing booking | `BookingRequest` | `string`                       | -               |
| PATCH  | `/cancel/{id}` | Cancel booking          | -                | `string`                       | -               |

#### Query Parameters for GET /

- `page` (int, default: 1): Page number
- `pageSize` (int, default: 10): Items per page

---

### Futsal Ground Management

Base URL: `/FutsalGround`
**Authorization Required**

#### Endpoints

| Method | Endpoint    | Description                            | Request Body          | Response                            |
| ------ | ----------- | -------------------------------------- | --------------------- | ----------------------------------- |
| GET    | `/`         | Get all futsal grounds with pagination | -                     | `IEnumerable<FutsalGroundResponse>` |
| GET    | `/search`   | Search futsal grounds                  | -                     | `IEnumerable<FutsalGroundResponse>` |
| GET    | `/{id:int}` | Get futsal ground by ID                | -                     | `FutsalGroundResponse`              |
| POST   | `/`         | Create new futsal ground               | `FutsalGroundRequest` | `FutsalGroundResponse`              |
| PUT    | `/{id:int}` | Update existing futsal ground          | `FutsalGroundRequest` | `FutsalGroundResponse`              |
| DELETE | `/{id:int}` | Delete futsal ground                   | -                     | `Ok`                                |

#### Query Parameters for GET / and /search

- `page` (int): Page number
- `pageSize` (int): Items per page
- `name` (string): Search by name (for /search)
- `location` (string): Filter by location (for /search)
- `minRating` (double): Minimum average rating (for /search)

---

### Payment Management

Base URL: `/Payment`
**Authorization Required**

#### Endpoints

| Method | Endpoint           | Description               | Request Body     | Response                       |
| ------ | ------------------ | ------------------------- | ---------------- | ------------------------------ |
| GET    | `/`                | Get payments by user ID   | -                | `IEnumerable<PaymentResponse>` |
| GET    | `/{bookingId:int}` | Get payment by booking ID | -                | `PaymentResponse`              |
| POST   | `/`                | Create new payment        | `PaymentRequest` | `string`                       |

#### Query Parameters for GET /

- `page` (int): Page number
- `pageSize` (int): Items per page

---

### Payment Gateway Management

Base URL: `/PaymentGateway`
**Authorization Required**

#### Endpoints

| Method | Endpoint           | Description             | Request Body                   | Response                 |
| ------ | ------------------ | ----------------------- | ------------------------------ | ------------------------ |
| POST   | `/khalti/initiate` | Initiate Khalti payment | `KhaltiPaymentInitiateRequest` | `KhaltiInitiateResponse` |
| POST   | `/khalti/callback` | Process Khalti callback | -                              | `string`                 |
| POST   | `/khalti/webhook`  | Process Khalti webhook  | `KhaltiWebhookPayload`         | `string`                 |

---

### Review Management

Base URL: `/Reviews`
**Authorization Required**

#### Endpoints

| Method | Endpoint                 | Description                     | Request Body    | Response                      |
| ------ | ------------------------ | ------------------------------- | --------------- | ----------------------------- |
| GET    | `/`                      | Get all reviews with pagination | -               | `IEnumerable<ReviewResponse>` |
| GET    | `/Ground/{groundId:int}` | Get reviews for specific ground | -               | `IEnumerable<ReviewResponse>` |
| GET    | `/{id:int}`              | Get review by ID                | -               | `ReviewResponse`              |
| POST   | `/`                      | Create new review               | `ReviewRequest` | `ReviewResponse`              |
| PUT    | `/{id:int}`              | Update existing review          | `ReviewRequest` | `ReviewResponse`              |
| DELETE | `/{id:int}`              | Delete review                   | -               | `Ok`                          |

#### Query Parameters for GET endpoints

- `page` (int): Page number
- `pageSize` (int): Items per page

---

### Images Management

Base URL: `/images`
**Authorization Required**

#### Endpoints

| Method | Endpoint                    | Description                    | Request Body          | Response                 |
| ------ | --------------------------- | ------------------------------ | --------------------- | ------------------------ |
| POST   | `/upload/single`            | Upload a single image file     | `multipart/form-data` | `Image`                  |
| POST   | `/upload/multiple`          | Upload multiple image files    | `multipart/form-data` | `List<Image>`            |
| DELETE | `/delete/single/{imageUrl}` | Delete a single image by URL   | -                     | `NoContent`/`NotFound`   |
| DELETE | `/delete/multiple`          | Delete multiple images by URLs | `List<string>`        | `NoContent`/`BadRequest` |
| GET    | `/user`                     | Get images for current user    | -                     | `List<Image>`            |

#### Notes

- For single delete, `imageUrl` is passed as a route parameter (URL-encoded if needed).
- For multiple delete, provide a JSON array of image URLs in the request body.

#### Example: Delete Single Image

```
DELETE /images/delete/single/https%3A%2F%2Fexample.com%2Fimg%2Fabc.jpg
Authorization: Bearer <token>
```

#### Example: Delete Multiple Images

```
DELETE /images/delete/multiple
Content-Type: application/json
Authorization: Bearer <token>

[
    "https://example.com/img/abc.jpg",
    "https://example.com/img/xyz.jpg"
]
```

---

### Notification Management

Base URL: `/Notifications`
**Authorization Required**

#### Endpoints

| Method | Endpoint                | Description                         | Request Body            | Response                            |
| ------ | ----------------------- | ----------------------------------- | ----------------------- | ----------------------------------- |
| GET    | `/`                     | Get notifications by user ID        | -                       | `IEnumerable<NotificationResponse>` |
| POST   | `/Send`                 | Send notification to multiple users | `NotificationListModel` | `string`                            |
| PUT    | `/{notificationId:int}` | Update notification status          | -                       | `string`                            |

#### Query Parameters for GET /

- `page` (int): Page number
- `pageSize` (int): Items per page

---

## Data Models

### Request Models

#### BookingRequest

```csharp
public class BookingRequest
{
    public required string UserId { get; set; }
    public int GroundId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
}
```

#### FutsalGroundRequest

```csharp
public class FutsalGroundRequest
{
    public string Name { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public decimal PricePerHour { get; set; }
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }
}
```

#### PaymentRequest

```csharp
public class PaymentRequest
{
    public int BookingId { get; set; }
    public PaymentMethod Method { get; set; }
    public string? TransactionId { get; set; }
    public decimal AmountPaid { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
}
```

#### KhaltiPaymentInitiateRequest

```csharp
public class KhaltiPaymentInitiateRequest
{
    public int BookingId { get; set; }
    public string ReturnUrl { get; set; } = string.Empty;
    public string WebsiteUrl { get; set; } = string.Empty;
}
```

#### ReviewRequest

```csharp
public class ReviewRequest
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public int GroundId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
}
```

#### NotificationListModel

```csharp
public class NotificationListModel
{
    public required List<string> UserId { get; set; }
    public string Message { get; set; } = string.Empty;
}
```

#### RoleRequest

```csharp
public class RoleRequest
{
    public string Name { get; set; } = string.Empty;
}
```

---

### Response Models

#### BookingResponse

```csharp
public class BookingResponse
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public int GroundId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public BookingStatus Status { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public string GroundName { get; set; } = string.Empty;
}
```

#### FutsalGroundResponse

```csharp
public class FutsalGroundResponse
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public decimal PricePerHour { get; set; }
    public double AverageRating { get; set; }
    public int RatingCount { get; set; } = 0;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public string OwnerName { get; set; } = string.Empty;
    public List<BookedTimeSlot> BookedTimeSlots { get; set; } = new();
}
```

#### BookedTimeSlot

```csharp
public class BookedTimeSlot
{
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
}
```

#### PaymentResponse

```csharp
public class PaymentResponse
{
    public int Id { get; set; }
    public decimal? RemainingAmount { get; set; }
    public int BookingId { get; set; }
    public PaymentMethod Method { get; set; }
    public string? TransactionId { get; set; }
    public decimal AmountPaid { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;
}
```

#### ReviewResponse

```csharp
public class ReviewResponse
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string UserImageUrl { get; set; } = string.Empty;
    public string ReviewImageUrl { get; set; } = string.Empty;
    public int GroundId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

#### NotificationResponse

```csharp
public class NotificationResponse
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public DateTime? ReadAt { get; set; } = null;
    public DateTime CreatedAt { get; set; }
}
```

---

### Database Entities (DTOs)

#### User

```csharp
public class User : IdentityUser
{
    public string? ImageUrl { get; set; } = null;
}
```

#### Role

```csharp
public class Role : IdentityRole
{
    // Inherits from IdentityRole
}
```

#### UserRole

```csharp
public class UserRole : IdentityUserRole<string>
{
    // Inherits from IdentityUserRole
}
```

#### Booking

```csharp
public class Booking
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public int GroundId { get; set; }
    public DateTime BookingDate { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public BookingStatus Status { get; set; } = BookingStatus.Pending;
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; } = null;

    // Navigation Properties
    public User User { get; set; } = null!;
    public FutsalGround Ground { get; set; } = null!;
}
```

#### FutsalGround

```csharp
public class FutsalGround
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public decimal PricePerHour { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string Description { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public double AverageRating { get; set; } = 0.0;
    public int RatingCount { get; set; } = 0;
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; } = null;
    public bool IsActive { get; set; } = true;

    // Navigation Properties
    public User Owner { get; set; } = null!;
}
```

#### Payment

```csharp
public class Payment
{
    public int Id { get; set; }
    public int BookingId { get; set; }
    public PaymentMethod Method { get; set; }
    public string? TransactionId { get; set; }
    public decimal AmountPaid { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public DateTime PaymentDate { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    public Booking Booking { get; set; } = null!;
}
```

#### Review

```csharp
public class Review
{
    public int Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public int GroundId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; } = null;
    public string? ImageUrl { get; set; } = null;

    // Navigation Properties
    public User User { get; set; } = null!;
    public FutsalGround Ground { get; set; } = null!;
}
```

#### Notification

```csharp
public class Notification
{
    public int Id { get; set; }
    public required string UserId { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsRead { get; set; } = false;
    public DateTime? ReadAt { get; set; } = null;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    public User User { get; set; } = null!;
}
```

#### Image

```csharp
public class Image
{
    public int Id { get; set; }
    public string Url { get; set; } = default!;
    public ImageEntityType EntityType { get; set; }
    public string? EntityId { get; set; }
    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;
}
```

#### GroundClosure

```csharp
public class GroundClosure
{
    public int Id { get; set; }
    public int GroundId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? Reason { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation Properties
    public virtual FutsalGround? Ground { get; set; } = null!;
}
```

---

### Enums

#### BookingStatus

```csharp
public enum BookingStatus
{
    Pending,
    Confirmed,
    Cancelled,
    Completed
}
```

#### PaymentMethod

```csharp
public enum PaymentMethod
{
    Cash,
    Online
}
```

#### PaymentStatus

```csharp
public enum PaymentStatus
{
    Pending,
    PartiallyCompleted,
    Completed,
    Failed
}
```

#### ImageEntityType

```csharp
public enum ImageEntityType
{
    Review,
    Ground,
    User
}
```

---

## Authentication & Authorization

- **Bearer Token Authentication**: Most endpoints require authentication via Bearer token
- **Permission-based Authorization**: Some endpoints require specific permissions (e.g., `CanView:Booking`)
- **Role-based Access**: User roles determine access to different functionalities
- **Google OAuth**: Supported for user authentication

## Common Response Codes

- **200 OK**: Successful request
- **201 Created**: Resource created successfully
- **204 No Content**: Successful request with no content
- **400 Bad Request**: Invalid request data
- **401 Unauthorized**: Authentication required or failed
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **500 Internal Server Error**: Server error

## Pagination

Most list endpoints support pagination with the following query parameters:

- `page`: Page number (default: 1)
- `pageSize`: Number of items per page (default: 10)

## Notes

- All dates are in UTC format
- Decimal values are used for monetary amounts
- TimeSpan is used for time intervals (e.g., booking duration, opening hours)
- Foreign key relationships are maintained between entities
- Soft delete is implemented for some entities (IsActive flag)
