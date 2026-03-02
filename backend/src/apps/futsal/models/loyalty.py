from datetime import datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .booking import Booking


class LoyaltyTransactionType(str, Enum):
    EARNED = "earned"
    REDEEMED = "redeemed"
    EXPIRED = "expired"
    BONUS = "bonus"
    REFUNDED = "refunded"


class LoyaltyAccount(SQLModel, table=True):
    __tablename__ = "loyalty_accounts"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", unique=True, index=True)
    points_balance: int = Field(default=0, ge=0)
    total_earned: int = Field(default=0, ge=0)
    total_redeemed: int = Field(default=0, ge=0)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship()
    transactions: list["LoyaltyTransaction"] = Relationship(back_populates="account")


class LoyaltyTransaction(SQLModel, table=True):
    __tablename__ = "loyalty_transactions"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    account_id: int = Field(foreign_key="loyalty_accounts.id", index=True)
    booking_id: Optional[int] = Field(default=None, foreign_key="bookings.id")
    transaction_type: LoyaltyTransactionType
    points: int  # positive = earned/bonus, negative = redeemed/expired
    description: str = Field(max_length=255)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    account: Optional["LoyaltyAccount"] = Relationship(back_populates="transactions")
    booking: Optional["Booking"] = Relationship()
