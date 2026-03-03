"""
Subscription service: activate, renew, check status, grace period logic.
"""
from datetime import datetime, date, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.subscription.models.plan import SubscriptionPlan
from src.apps.subscription.models.subscription import OwnerSubscription, SubscriptionStatus
from src.apps.core.analytics import analytics

GRACE_PERIOD_DAYS = 3


async def get_subscription(db: AsyncSession, owner_id: int) -> Optional[OwnerSubscription]:
    result = await db.execute(
        select(OwnerSubscription).where(OwnerSubscription.owner_id == owner_id)
    )
    return result.scalars().first()


async def start_trial(
    db: AsyncSession, owner_id: int, plan_id: int
) -> OwnerSubscription:
    """Start a free trial subscription for a new owner."""
    plan = await db.get(SubscriptionPlan, plan_id)
    if not plan:
        raise ValueError("Plan not found.")

    trial_end = datetime.utcnow() + timedelta(days=plan.trial_days) if plan.trial_days > 0 else None
    sub = OwnerSubscription(
        owner_id=owner_id,
        plan_id=plan_id,
        status=SubscriptionStatus.TRIALING if trial_end else SubscriptionStatus.EXPIRED,
        trial_ends_at=trial_end,
    )
    db.add(sub)
    await db.commit()
    await db.refresh(sub)
    analytics.track(
        distinct_id=str(owner_id),
        event="trial_started",
        properties={"plan_id": plan_id, "trial_days": plan.trial_days},
    )
    return sub


async def activate_subscription(
    db: AsyncSession,
    owner_id: int,
    plan_id: int,
    transaction_id: int,
) -> OwnerSubscription:
    """Called after a successful payment. Activates or renews subscription."""
    sub = await get_subscription(db, owner_id)
    today = date.today()

    if sub:
        # Renew: extend from current_period_end or today, whichever is later
        start = max(sub.current_period_end, today) if sub.current_period_end else today
        sub.plan_id = plan_id
        sub.status = SubscriptionStatus.ACTIVE
        sub.current_period_start = start
        sub.current_period_end = start + timedelta(days=30)
        sub.last_payment_transaction_id = transaction_id
        sub.cancel_at_period_end = False
        sub.updated_at = datetime.utcnow()
    else:
        sub = OwnerSubscription(
            owner_id=owner_id,
            plan_id=plan_id,
            status=SubscriptionStatus.ACTIVE,
            current_period_start=today,
            current_period_end=today + timedelta(days=30),
            last_payment_transaction_id=transaction_id,
        )

    db.add(sub)
    await db.commit()
    await db.refresh(sub)

    analytics.track(
        distinct_id=str(owner_id),
        event="subscription_activated",
        properties={
            "plan_id": plan_id,
            "transaction_id": transaction_id,
            "period_end": str(sub.current_period_end),
        },
    )
    analytics.identify(
        distinct_id=str(owner_id),
        properties={"subscription_active": True, "subscription_plan_id": plan_id},
    )
    return sub


async def cancel_subscription(
    db: AsyncSession, owner_id: int, immediately: bool = False
) -> OwnerSubscription:
    sub = await get_subscription(db, owner_id)
    if not sub:
        raise ValueError("No active subscription found.")

    if immediately:
        sub.status = SubscriptionStatus.CANCELLED
        sub.cancelled_at = datetime.utcnow()
    else:
        sub.cancel_at_period_end = True

    sub.updated_at = datetime.utcnow()
    db.add(sub)
    await db.commit()
    await db.refresh(sub)
    analytics.track(
        distinct_id=str(owner_id),
        event="subscription_cancelled",
        properties={"plan_id": sub.plan_id, "immediately": immediately},
    )
    analytics.identify(
        distinct_id=str(owner_id),
        properties={"subscription_active": False},
    )
    return sub


def is_subscription_active(sub: Optional[OwnerSubscription]) -> bool:
    """Return True if the owner has dashboard access (active, trialing, or grace)."""
    if sub is None:
        return False
    now = datetime.utcnow()
    if sub.status == SubscriptionStatus.TRIALING:
        return sub.trial_ends_at is None or sub.trial_ends_at > now
    if sub.status in (SubscriptionStatus.ACTIVE, SubscriptionStatus.PAST_DUE):
        return True
    if sub.status == SubscriptionStatus.GRACE:
        return True  # grace period — still accessible
    return False


async def refresh_subscription_statuses(db: AsyncSession) -> dict:
    """Celery task: mark expired subs, move to grace or expired."""
    today = date.today()
    grace_cutoff = today - timedelta(days=GRACE_PERIOD_DAYS)
    updated = {"to_grace": 0, "to_expired": 0, "reminders_sent": 0}

    result = await db.execute(
        select(OwnerSubscription).where(
            OwnerSubscription.status.in_([
                SubscriptionStatus.ACTIVE,
                SubscriptionStatus.GRACE,
                SubscriptionStatus.PAST_DUE,
                SubscriptionStatus.TRIALING,
            ])
        )
    )
    subs = result.scalars().all()

    for sub in subs:
        # Check trial expiry
        if sub.status == SubscriptionStatus.TRIALING:
            if sub.trial_ends_at and sub.trial_ends_at.date() < today:
                sub.status = SubscriptionStatus.GRACE
                updated["to_grace"] += 1
            continue

        # Check period expiry
        if sub.current_period_end and sub.current_period_end < today:
            if sub.current_period_end >= grace_cutoff:
                # Within 3-day grace window
                if sub.status != SubscriptionStatus.GRACE:
                    sub.status = SubscriptionStatus.GRACE
                    updated["to_grace"] += 1
            else:
                # Past grace window — hard expire
                if sub.status != SubscriptionStatus.EXPIRED:
                    sub.status = SubscriptionStatus.EXPIRED
                    updated["to_expired"] += 1

            # Handle cancel_at_period_end
            if sub.cancel_at_period_end and sub.current_period_end < today:
                sub.status = SubscriptionStatus.CANCELLED
                sub.cancelled_at = datetime.utcnow()

        sub.updated_at = datetime.utcnow()
        db.add(sub)

    await db.commit()
    return updated
