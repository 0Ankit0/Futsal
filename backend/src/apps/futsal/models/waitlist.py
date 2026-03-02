from datetime import date, datetime, time
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .ground import FutsalGround


class WaitlistEntry(SQLModel, table=True):
    __tablename__ = "waitlist_entries"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    ground_id: int = Field(foreign_key="futsal_grounds.id", index=True)
    booking_date: date = Field(index=True)
    start_time: time
    end_time: time
    is_active: bool = Field(default=True)
    notified_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    user: Optional["User"] = Relationship()
    ground: Optional["FutsalGround"] = Relationship()
