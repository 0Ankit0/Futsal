from datetime import date, datetime, time
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship
import uuid

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .ground import FutsalGround
    from .review import Review


class BookingStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"


class RecurringType(str, Enum):
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class BookingBase(SQLModel):
    user_id: int = Field(foreign_key="user.id", index=True)
    ground_id: int = Field(foreign_key="futsal_grounds.id", index=True)
    booking_date: date = Field(index=True)
    start_time: time
    end_time: time
    total_amount: float = Field(ge=0)
    paid_amount: float = Field(default=0.0, ge=0)
    is_recurring: bool = Field(default=False)
    recurring_type: Optional[RecurringType] = Field(default=None)
    recurring_end_date: Optional[date] = Field(default=None)
    team_name: Optional[str] = Field(default=None, max_length=100)
    notes: Optional[str] = Field(default=None, max_length=500)
    cancellation_reason: Optional[str] = Field(default=None, max_length=300)


class Booking(BookingBase, table=True):
    __tablename__ = "bookings"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    status: BookingStatus = Field(default=BookingStatus.PENDING)
    qr_code: str = Field(default_factory=lambda: str(uuid.uuid4()), unique=True, index=True)
    qr_used: bool = Field(default=False)
    cancelled_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship()
    ground: Optional["FutsalGround"] = Relationship(back_populates="bookings")
    review: Optional["Review"] = Relationship(back_populates="booking")
