"""
Subscription API: plan management (superuser) + subscribe/renew/cancel (owner).
"""
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.iam.api.deps import get_db, get_current_user as get_current_active_user
from src.apps.iam.models.user import User
from src.apps.subscription.models.plan import SubscriptionPlan
from src.apps.subscription.models.subscription import OwnerSubscription, SubscriptionStatus
from src.apps.subscription.services.subscription_service import (
    get_subscription,
    start_trial,
    activate_subscription,
    cancel_subscription,
    is_subscription_active,
)

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])


# ── Schemas ────────────────────────────────────────────────────────────────────

class PlanCreate(BaseModel):
    name: str
    slug: str
    description: Optional[str] = None
    price_monthly: float
    max_grounds: int = 1
    max_staff: int = 2
    trial_days: int = 14
    features: Optional[str] = None
    is_public: bool = True


class PlanResponse(BaseModel):
    id: int
    name: str
    slug: str
    description: Optional[str]
    price_monthly: float
    max_grounds: int
    max_staff: int
    trial_days: int
    features: Optional[str]
    is_active: bool
    is_public: bool


class SubscriptionStatusResponse(BaseModel):
    status: SubscriptionStatus
    plan: Optional[PlanResponse]
    current_period_end: Optional[str]
    trial_ends_at: Optional[str]
    cancel_at_period_end: bool
    is_active: bool


class PaymentInitiateRequest(BaseModel):
    plan_id: int
    provider: str  # khalti | esewa | stripe
    return_url: str  # frontend callback URL


class PaymentVerifyRequest(BaseModel):
    plan_id: int
    transaction_id: int
    provider_token: str  # Khalti token or eSewa refId


# ── Public: List Plans ─────────────────────────────────────────────────────────

@router.get("/plans", response_model=list[PlanResponse])
async def list_plans(db: AsyncSession = Depends(get_db)):
    """Public endpoint — anyone can view available subscription plans."""
    result = await db.execute(
        select(SubscriptionPlan).where(
            SubscriptionPlan.is_active == True,
            SubscriptionPlan.is_public == True,
        )
    )
    return result.scalars().all()


# ── Superuser: Plan management ─────────────────────────────────────────────────

@router.post("/plans", response_model=PlanResponse, status_code=201)
async def create_plan(
    data: PlanCreate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Superuser only: create a new subscription plan."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser access required.")
    plan = SubscriptionPlan(**data.model_dump())
    db.add(plan)
    await db.commit()
    await db.refresh(plan)
    return plan


@router.patch("/plans/{plan_id}", response_model=PlanResponse)
async def update_plan(
    plan_id: int,
    data: dict,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Superuser only: update plan fields."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser access required.")
    plan = await db.get(SubscriptionPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found.")
    for key, val in data.items():
        if hasattr(plan, key) and key not in ("id", "created_at"):
            setattr(plan, key, val)
    plan.updated_at = datetime.utcnow()
    db.add(plan)
    await db.commit()
    await db.refresh(plan)
    return plan


# ── Superuser: view all subscriptions ────────────────────────────────────────

@router.get("/admin/all", tags=["admin"])
async def list_all_subscriptions(
    skip: int = 0,
    limit: int = 50,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser access required.")
    result = await db.execute(select(OwnerSubscription).offset(skip).limit(limit))
    return result.scalars().all()


@router.patch("/admin/{owner_id}/activate", tags=["admin"])
async def manually_activate_subscription(
    owner_id: int,
    plan_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Superuser: manually activate subscription (e.g., after manual bank transfer)."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser access required.")
    sub = await activate_subscription(db, owner_id, plan_id, transaction_id=0)
    return sub


# ── Owner: get subscription status ────────────────────────────────────────────

@router.get("/me", response_model=SubscriptionStatusResponse)
async def my_subscription(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    sub = await get_subscription(db, current_user.id)
    plan = await db.get(SubscriptionPlan, sub.plan_id) if sub else None
    return SubscriptionStatusResponse(
        status=sub.status if sub else SubscriptionStatus.EXPIRED,
        plan=plan,
        current_period_end=sub.current_period_end.isoformat() if sub and sub.current_period_end else None,
        trial_ends_at=sub.trial_ends_at.isoformat() if sub and sub.trial_ends_at else None,
        cancel_at_period_end=sub.cancel_at_period_end if sub else False,
        is_active=is_subscription_active(sub),
    )


# ── Owner: start trial ─────────────────────────────────────────────────────────

@router.post("/trial/{plan_id}", status_code=201)
async def start_trial_subscription(
    plan_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Start a free trial for the owner. Only once; raises 409 if already subscribed."""
    existing = await get_subscription(db, current_user.id)
    if existing:
        raise HTTPException(status_code=409, detail="You already have a subscription record.")
    sub = await start_trial(db, current_user.id, plan_id)
    return sub


# ── Owner: verify payment and activate ────────────────────────────────────────

@router.post("/verify-payment")
async def verify_payment_and_activate(
    req: PaymentVerifyRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Called by the frontend after Khalti/eSewa redirects back with a token.
    Looks up the PaymentTransaction, confirms it's completed, then activates subscription.
    """
    from src.apps.finance.models.payment import PaymentTransaction, PaymentStatus

    tx = await db.get(PaymentTransaction, req.transaction_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Payment transaction not found.")
    if tx.status != PaymentStatus.COMPLETED:
        raise HTTPException(
            status_code=402,
            detail="Payment has not been completed. Please complete the payment first.",
        )

    sub = await activate_subscription(db, current_user.id, req.plan_id, req.transaction_id)
    return {"message": "Subscription activated.", "subscription": sub}


# ── Owner: cancel subscription ─────────────────────────────────────────────────

@router.post("/cancel")
async def cancel_my_subscription(
    immediately: bool = False,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    sub = await cancel_subscription(db, current_user.id, immediately=immediately)
    msg = "Subscription cancelled immediately." if immediately else "Subscription will cancel at end of current period."
    return {"message": msg, "subscription": sub}
