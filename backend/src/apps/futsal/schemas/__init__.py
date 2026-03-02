from datetime import date, time
from typing import Optional, List
from sqlmodel import SQLModel
from src.apps.futsal.models.ground import GroundType


class GroundCreate(SQLModel):
    name: str
    location: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: Optional[str] = None
    ground_type: GroundType = GroundType.OUTDOOR
    price_per_hour: float
    weekend_price_per_hour: Optional[float] = None
    peak_hours_start: Optional[time] = None
    peak_hours_end: Optional[time] = None
    peak_price_multiplier: float = 1.0
    open_time: time
    close_time: time
    slot_duration_minutes: int = 60
    amenities: Optional[dict] = None


class GroundUpdate(SQLModel):
    name: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: Optional[str] = None
    ground_type: Optional[GroundType] = None
    price_per_hour: Optional[float] = None
    weekend_price_per_hour: Optional[float] = None
    peak_hours_start: Optional[time] = None
    peak_hours_end: Optional[time] = None
    peak_price_multiplier: Optional[float] = None
    open_time: Optional[time] = None
    close_time: Optional[time] = None
    slot_duration_minutes: Optional[int] = None
    amenities: Optional[dict] = None
    is_active: Optional[bool] = None


class GroundResponse(SQLModel):
    id: int
    name: str
    slug: str
    owner_id: int
    location: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    description: Optional[str] = None
    ground_type: GroundType
    price_per_hour: float
    weekend_price_per_hour: Optional[float] = None
    peak_hours_start: Optional[time] = None
    peak_hours_end: Optional[time] = None
    peak_price_multiplier: float
    open_time: time
    close_time: time
    slot_duration_minutes: int
    is_active: bool
    is_verified: bool
    average_rating: float
    rating_count: int
    amenities: Optional[dict] = None


class SlotResponse(SQLModel):
    start_time: time
    end_time: time
    is_available: bool
    is_locked: bool
    price: float


class GroundClosureCreate(SQLModel):
    start_date: date
    end_date: date
    reason: Optional[str] = None


class BookingCreate(SQLModel):
    ground_id: int
    booking_date: date
    start_time: time
    end_time: time
    team_name: Optional[str] = None
    notes: Optional[str] = None
    is_recurring: bool = False
    recurring_type: Optional[str] = None
    recurring_end_date: Optional[date] = None
    loyalty_points_to_redeem: int = 0


class BookingResponse(SQLModel):
    id: int
    user_id: int
    ground_id: int
    booking_date: date
    start_time: time
    end_time: time
    status: str
    total_amount: float
    paid_amount: float
    team_name: Optional[str] = None
    notes: Optional[str] = None
    qr_code: str
    is_recurring: bool
    recurring_type: Optional[str] = None
    recurring_end_date: Optional[date] = None
    cancellation_reason: Optional[str] = None


class ReviewCreate(SQLModel):
    rating: int
    comment: Optional[str] = None
    image_url: Optional[str] = None


class ReviewResponse(SQLModel):
    id: int
    user_id: int
    ground_id: int
    booking_id: int
    rating: int
    comment: Optional[str] = None
    image_url: Optional[str] = None
    owner_reply: Optional[str] = None
    is_verified: bool


class OwnerReplyCreate(SQLModel):
    reply: str


class LoyaltyAccountResponse(SQLModel):
    points_balance: int
    total_earned: int
    total_redeemed: int


class LoyaltyTransactionResponse(SQLModel):
    id: int
    transaction_type: str
    points: int
    description: str
