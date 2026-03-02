from datetime import datetime, time
from enum import Enum
from typing import Optional, List, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship, Column
from sqlalchemy import JSON

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from .ground_image import GroundImage
    from .booking import Booking
    from .review import Review
    from .ground_closure import GroundClosure
    from .favourite import FavouriteGround


class GroundType(str, Enum):
    INDOOR = "indoor"
    OUTDOOR = "outdoor"
    HYBRID = "hybrid"


class FutsalGroundBase(SQLModel):
    name: str = Field(max_length=100)
    slug: str = Field(unique=True, index=True, max_length=120)
    owner_id: int = Field(foreign_key="user.id", index=True)
    location: str = Field(max_length=255)
    latitude: Optional[float] = Field(default=None)
    longitude: Optional[float] = Field(default=None)
    description: Optional[str] = Field(default=None, max_length=1000)
    ground_type: GroundType = Field(default=GroundType.OUTDOOR)
    price_per_hour: float = Field(gt=0)
    weekend_price_per_hour: Optional[float] = Field(default=None, gt=0)
    peak_hours_start: Optional[time] = Field(default=None)
    peak_hours_end: Optional[time] = Field(default=None)
    peak_price_multiplier: float = Field(default=1.0, ge=1.0, le=3.0)
    open_time: time = Field(default=time(6, 0))
    close_time: time = Field(default=time(22, 0))
    slot_duration_minutes: int = Field(default=60, ge=30, le=180)
    is_active: bool = Field(default=True)
    is_verified: bool = Field(default=False)
    average_rating: float = Field(default=0.0, ge=0.0, le=5.0)
    rating_count: int = Field(default=0, ge=0)


class FutsalGround(FutsalGroundBase, table=True):
    __tablename__ = "futsal_grounds"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    amenities: Optional[dict] = Field(default=None, sa_column=Column(JSON))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    owner: Optional["User"] = Relationship()
    images: List["GroundImage"] = Relationship(back_populates="ground")
    bookings: List["Booking"] = Relationship(back_populates="ground")
    reviews: List["Review"] = Relationship(back_populates="ground")
    closures: List["GroundClosure"] = Relationship(back_populates="ground")
    favourites: List["FavouriteGround"] = Relationship(back_populates="ground")
