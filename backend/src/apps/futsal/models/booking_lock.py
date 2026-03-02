from datetime import date, datetime, time
from typing import Optional
from sqlmodel import Field, SQLModel, UniqueConstraint


class BookingLock(SQLModel, table=True):
    """
    Short-lived exclusive lock on a time slot during payment flow.
    Prevents two users from booking the same slot simultaneously.
    TTL: 10 minutes. Released by Celery task or on payment completion.
    """
    __tablename__ = "booking_locks"  # type: ignore
    __table_args__ = (
        UniqueConstraint("ground_id", "booking_date", "start_time", "end_time",
                         name="uq_booking_lock_slot"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    ground_id: int = Field(foreign_key="futsal_grounds.id", index=True)
    booking_date: date = Field(index=True)
    start_time: time
    end_time: time
    locked_by_booking_id: Optional[int] = Field(default=None, foreign_key="bookings.id")
    locked_by_user_id: int = Field(foreign_key="user.id")
    locked_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: datetime  # locked_at + 10 minutes
