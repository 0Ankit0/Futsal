from datetime import date, datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .owner_gateway import GatewayProvider


class PayoutStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    ON_HOLD = "on_hold"


class PayoutRecord(SQLModel, table=True):
    __tablename__ = "payout_records"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    owner_id: int = Field(foreign_key="user.id", index=True)
    ground_id: Optional[int] = Field(default=None, foreign_key="futsal_grounds.id", index=True)
    period_start: date
    period_end: date
    total_bookings: int = Field(default=0, ge=0)
    gross_amount: float = Field(ge=0)
    platform_fee_pct: float = Field(default=5.0, ge=0, le=100)
    platform_fee: float = Field(ge=0)
    net_amount: float = Field(ge=0)
    currency: str = Field(default="NPR", max_length=3)
    status: PayoutStatus = Field(default=PayoutStatus.PENDING)
    # PLATFORM = platform transferred to owner | DIRECT = no transfer, owner already had it
    payout_mode: str = Field(default="PLATFORM", max_length=10)
    provider: Optional[str] = Field(default=None, max_length=50)
    transaction_ref: Optional[str] = Field(default=None, max_length=255)
    retry_count: int = Field(default=0, ge=0)
    last_error: Optional[str] = Field(default=None, max_length=500)
    initiated_at: Optional[datetime] = Field(default=None)
    completed_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    owner: Optional["User"] = Relationship()
    ledger_entries: list["PayoutLedger"] = Relationship(back_populates="payout")
