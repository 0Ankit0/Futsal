"""
Slot availability service.
Computes available time slots for a given ground on a given date,
respecting: operating hours, slot duration, existing bookings,
booking locks, and ground closures.
"""
from datetime import date, datetime, time, timedelta
from typing import List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.booking_lock import BookingLock
from src.apps.futsal.models.ground_closure import GroundClosure
from src.apps.futsal.schemas import SlotResponse


def _time_to_minutes(t: time) -> int:
    return t.hour * 60 + t.minute


def _minutes_to_time(m: int) -> time:
    return time(m // 60, m % 60)


def _is_weekend(d: date) -> bool:
    return d.weekday() >= 5  # Saturday=5, Sunday=6


def _is_peak_hour(slot_start: time, peak_start: time | None, peak_end: time | None) -> bool:
    if peak_start is None or peak_end is None:
        return False
    return peak_start <= slot_start < peak_end


async def get_available_slots(
    db: AsyncSession,
    ground: FutsalGround,
    booking_date: date,
) -> List[SlotResponse]:
    """Return all slots for the ground on the given date with availability status."""
    # Check if ground is closed on this date
    closure = await db.execute(
        select(GroundClosure).where(
            GroundClosure.ground_id == ground.id,
            GroundClosure.start_date <= booking_date,
            GroundClosure.end_date >= booking_date,
        )
    )
    if closure.scalars().first():
        return []  # Ground closed — no slots

    # Fetch confirmed/pending bookings for this date
    bookings_result = await db.execute(
        select(Booking).where(
            Booking.ground_id == ground.id,
            Booking.booking_date == booking_date,
            Booking.status.in_([BookingStatus.PENDING, BookingStatus.CONFIRMED]),
        )
    )
    booked_slots: list[tuple[time, time]] = [
        (b.start_time, b.end_time) for b in bookings_result.scalars().all()
    ]

    # Fetch active booking locks (not expired)
    now = datetime.utcnow()
    locks_result = await db.execute(
        select(BookingLock).where(
            BookingLock.ground_id == ground.id,
            BookingLock.booking_date == booking_date,
            BookingLock.expires_at > now,
        )
    )
    locked_slots: list[tuple[time, time]] = [
        (lk.start_time, lk.end_time) for lk in locks_result.scalars().all()
    ]

    # Generate all possible slots
    open_min = _time_to_minutes(ground.open_time)
    close_min = _time_to_minutes(ground.close_time)
    duration = ground.slot_duration_minutes
    is_weekend = _is_weekend(booking_date)

    slots: List[SlotResponse] = []
    current = open_min
    while current + duration <= close_min:
        slot_start = _minutes_to_time(current)
        slot_end = _minutes_to_time(current + duration)

        # Compute price
        if is_weekend and ground.weekend_price_per_hour:
            base_price = ground.weekend_price_per_hour
        else:
            base_price = ground.price_per_hour

        if _is_peak_hour(slot_start, ground.peak_hours_start, ground.peak_hours_end):
            base_price *= ground.peak_price_multiplier

        price = base_price * (duration / 60)

        # Check overlap with booked slots
        def overlaps(start: time, end: time, existing: list[tuple[time, time]]) -> bool:
            for (es, ee) in existing:
                if start < ee and end > es:
                    return True
            return False

        is_booked = overlaps(slot_start, slot_end, booked_slots)
        is_locked = overlaps(slot_start, slot_end, locked_slots)

        slots.append(SlotResponse(
            start_time=slot_start,
            end_time=slot_end,
            is_available=not is_booked and not is_locked,
            is_locked=is_locked,
            price=round(price, 2),
        ))
        current += duration

    return slots
