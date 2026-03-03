"""
Admin analytics endpoint — superuser only.

GET /futsal/admin/analytics/summary
GET /futsal/admin/analytics/daily-trend
"""
from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.iam.api.deps import get_db, get_current_active_superuser
from src.apps.iam.models.user import User
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.ground import FutsalGround
from src.apps.payout.models.payout_record import PayoutRecord, PayoutStatus
from src.apps.subscription.models.subscription import OwnerSubscription, SubscriptionStatus
from src.apps.subscription.models.plan import SubscriptionPlan

router = APIRouter(prefix="/admin/analytics", tags=["Admin Analytics"])


@router.get("/summary")
async def analytics_summary(
    _: Annotated[User, Depends(get_current_active_superuser)],
    db: AsyncSession = Depends(get_db),
):
    """Platform-wide KPI summary for superuser dashboard."""
    today = date.today()
    day_30_ago = today - timedelta(days=30)
    day_7_ago  = today - timedelta(days=7)

    # ── Users ────────────────────────────────────────────────────────────────
    total_users_result = await db.execute(select(func.count(User.id)))
    total_users: int = total_users_result.scalar() or 0

    new_users_30d_result = await db.execute(
        select(func.count(User.id)).where(func.date(User.created_at) >= day_30_ago)
    )
    new_users_30d: int = new_users_30d_result.scalar() or 0

    new_users_7d_result = await db.execute(
        select(func.count(User.id)).where(func.date(User.created_at) >= day_7_ago)
    )
    new_users_7d: int = new_users_7d_result.scalar() or 0

    # ── Grounds ──────────────────────────────────────────────────────────────
    total_grounds_result = await db.execute(select(func.count(FutsalGround.id)))
    total_grounds: int = total_grounds_result.scalar() or 0

    verified_grounds_result = await db.execute(
        select(func.count(FutsalGround.id)).where(FutsalGround.is_verified == True)  # noqa: E712
    )
    verified_grounds: int = verified_grounds_result.scalar() or 0

    # Unique owners with at least one ground
    total_owners_result = await db.execute(
        select(func.count(func.distinct(FutsalGround.owner_id)))
    )
    total_owners: int = total_owners_result.scalar() or 0

    # ── Bookings ─────────────────────────────────────────────────────────────
    active_statuses = [BookingStatus.CONFIRMED, BookingStatus.COMPLETED]

    total_bookings_30d_result = await db.execute(
        select(func.count(Booking.id)).where(
            and_(
                Booking.booking_date >= day_30_ago,
                Booking.status.in_(active_statuses),
            )
        )
    )
    total_bookings_30d: int = total_bookings_30d_result.scalar() or 0

    total_bookings_7d_result = await db.execute(
        select(func.count(Booking.id)).where(
            and_(
                Booking.booking_date >= day_7_ago,
                Booking.status.in_(active_statuses),
            )
        )
    )
    total_bookings_7d: int = total_bookings_7d_result.scalar() or 0

    total_bookings_today_result = await db.execute(
        select(func.count(Booking.id)).where(
            and_(
                Booking.booking_date == today,
                Booking.status.in_(active_statuses),
            )
        )
    )
    total_bookings_today: int = total_bookings_today_result.scalar() or 0

    # ── Revenue (platform fee) ────────────────────────────────────────────────
    platform_rev_30d_result = await db.execute(
        select(func.coalesce(func.sum(PayoutRecord.platform_fee), 0.0)).where(
            func.date(PayoutRecord.created_at) >= day_30_ago
        )
    )
    platform_revenue_30d: float = float(platform_rev_30d_result.scalar() or 0.0)

    total_gross_30d_result = await db.execute(
        select(func.coalesce(func.sum(PayoutRecord.gross_amount), 0.0)).where(
            func.date(PayoutRecord.created_at) >= day_30_ago
        )
    )
    total_gross_30d: float = float(total_gross_30d_result.scalar() or 0.0)

    # ── Payouts ───────────────────────────────────────────────────────────────
    on_hold_result = await db.execute(
        select(func.count(PayoutRecord.id)).where(
            PayoutRecord.status == PayoutStatus.ON_HOLD
        )
    )
    payout_on_hold: int = on_hold_result.scalar() or 0

    failed_result = await db.execute(
        select(func.count(PayoutRecord.id)).where(
            PayoutRecord.status == PayoutStatus.FAILED
        )
    )
    payout_failed: int = failed_result.scalar() or 0

    completed_result = await db.execute(
        select(func.count(PayoutRecord.id)).where(
            and_(
                PayoutRecord.status == PayoutStatus.COMPLETED,
                func.date(PayoutRecord.created_at) >= day_30_ago,
            )
        )
    )
    payouts_completed_30d: int = completed_result.scalar() or 0

    # ── Subscriptions ─────────────────────────────────────────────────────────
    active_subs_result = await db.execute(
        select(func.count(OwnerSubscription.id)).where(
            OwnerSubscription.status.in_([SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIALING])
        )
    )
    active_subscriptions: int = active_subs_result.scalar() or 0

    # Subscription revenue (active subscriptions × plan price)
    sub_revenue_result = await db.execute(
        select(func.coalesce(func.sum(SubscriptionPlan.price_monthly), 0.0))
        .join(OwnerSubscription, OwnerSubscription.plan_id == SubscriptionPlan.id)
        .where(OwnerSubscription.status == SubscriptionStatus.ACTIVE)
    )
    subscription_revenue_monthly: float = float(sub_revenue_result.scalar() or 0.0)

    return {
        "users": {
            "total": total_users,
            "new_last_30d": new_users_30d,
            "new_last_7d": new_users_7d,
        },
        "grounds": {
            "total": total_grounds,
            "verified": verified_grounds,
            "total_owners": total_owners,
        },
        "bookings": {
            "today": total_bookings_today,
            "last_7d": total_bookings_7d,
            "last_30d": total_bookings_30d,
        },
        "revenue": {
            "platform_fee_30d": platform_revenue_30d,
            "gross_30d": total_gross_30d,
            "subscription_monthly": subscription_revenue_monthly,
        },
        "payouts": {
            "on_hold": payout_on_hold,
            "failed": payout_failed,
            "completed_30d": payouts_completed_30d,
        },
        "subscriptions": {
            "active": active_subscriptions,
        },
    }


@router.get("/daily-trend")
async def analytics_daily_trend(
    _: Annotated[User, Depends(get_current_active_superuser)],
    db: AsyncSession = Depends(get_db),
    days: int = 30,
):
    """Daily booking count + gross revenue for the last N days."""
    today = date.today()
    start = today - timedelta(days=days - 1)
    active_statuses = [BookingStatus.CONFIRMED, BookingStatus.COMPLETED]

    # Aggregate bookings by date
    result = await db.execute(
        select(
            Booking.booking_date,
            func.count(Booking.id).label("count"),
            func.coalesce(func.sum(Booking.total_amount), 0.0).label("gross"),
        )
        .where(
            and_(
                Booking.booking_date >= start,
                Booking.booking_date <= today,
                Booking.status.in_(active_statuses),
            )
        )
        .group_by(Booking.booking_date)
        .order_by(Booking.booking_date)
    )
    rows = result.all()

    # Build a full date range, filling zeros for missing days
    data_by_date = {str(r.booking_date): {"count": r.count, "gross": float(r.gross)} for r in rows}
    trend = []
    for i in range(days):
        d = str(start + timedelta(days=i))
        trend.append({
            "date": d,
            "bookings": data_by_date.get(d, {}).get("count", 0),
            "revenue": data_by_date.get(d, {}).get("gross", 0.0),
        })

    return {"trend": trend, "days": days}
