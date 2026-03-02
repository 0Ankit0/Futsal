"""
Subscription plan model — created and managed by superuser.
Owners choose a plan and pay monthly to access the owner dashboard.
"""
from datetime import datetime
from typing import Optional
from sqlmodel import Field, SQLModel


class SubscriptionPlan(SQLModel, table=True):
    __tablename__ = "subscription_plans"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(max_length=100, description="Plan display name, e.g. 'Basic', 'Pro'")
    slug: str = Field(max_length=50, unique=True, index=True)
    description: Optional[str] = Field(default=None, max_length=500)
    price_monthly: float = Field(ge=0, description="Monthly price in NPR (0 = free tier)")
    max_grounds: int = Field(default=1, ge=1, description="Max grounds an owner can register")
    max_staff: int = Field(default=2, ge=0, description="Max staff/manager invites")
    trial_days: int = Field(default=0, ge=0, description="Free trial days for new subscribers")
    features: Optional[str] = Field(default=None, description="JSON list of feature strings")
    is_active: bool = Field(default=True)
    is_public: bool = Field(default=True, description="Shown to owners in plan picker")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)
