"""
Owner subscription model — tracks an owner's active subscription.
Payments reference the existing PaymentTransaction table.
"""
from datetime import datetime, date
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .plan import SubscriptionPlan


class SubscriptionStatus(str, Enum):
    TRIALING  = "trialing"   # within free trial window
    ACTIVE    = "active"     # paid and within period
    GRACE     = "grace"      # expired ≤3 days ago — dashboard still accessible
    EXPIRED   = "expired"    # hard-expired — dashboard locked
    CANCELLED = "cancelled"  # owner cancelled voluntarily
    PAST_DUE  = "past_due"   # payment failed but still in grace


class OwnerSubscription(SQLModel, table=True):
    __tablename__ = "owner_subscriptions"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    owner_id: int = Field(foreign_key="user.id", unique=True, index=True)
    plan_id: int = Field(foreign_key="subscription_plans.id")
    status: SubscriptionStatus = Field(default=SubscriptionStatus.TRIALING)

    trial_ends_at: Optional[datetime] = Field(default=None)
    current_period_start: Optional[date] = Field(default=None)
    current_period_end: Optional[date] = Field(default=None)

    # FK to the PaymentTransaction that last activated this period
    last_payment_transaction_id: Optional[int] = Field(
        default=None,
        foreign_key="payment_transactions.id",
        description="Most recent successful payment"
    )
    cancel_at_period_end: bool = Field(
        default=False,
        description="When True, cancel at current_period_end instead of renewing"
    )
    cancelled_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    owner: Optional["User"] = Relationship()
    plan: Optional["SubscriptionPlan"] = Relationship()
