"""
Booking service with race-condition-safe slot locking.
Uses SELECT FOR UPDATE to prevent simultaneous bookings on the same slot.
"""
from datetime import date, datetime, time, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.booking_lock import BookingLock
from src.apps.futsal.models.ground_closure import GroundClosure
from src.apps.futsal.schemas import BookingCreate
from src.apps.payout.models.payout_ledger import PayoutLedger
from src.apps.core.analytics import analytics

LOCK_TTL_MINUTES = 10
PLATFORM_FEE_PCT = 5.0
POINTS_PER_100_NPR = 1
CANCELLATION_GRACE_HOURS = 2


class SlotAlreadyBookedError(Exception):
    pass


class SlotLockedError(Exception):
    pass


class GroundClosedError(Exception):
    pass


class OutsideOperatingHoursError(Exception):
    pass


class BookingNotEligibleForCancelError(Exception):
    pass


async def _check_slot_available(
    db: AsyncSession,
    ground_id: int,
    booking_date: date,
    start_time: time,
    end_time: time,
    exclude_booking_id: Optional[int] = None,
) -> None:
    """
    Check for overlapping bookings using SELECT FOR UPDATE (row-level lock).
    Raises SlotAlreadyBookedError if the slot is taken.
    """
    stmt = (
        select(Booking)
        .where(
            Booking.ground_id == ground_id,
            Booking.booking_date == booking_date,
            Booking.status.in_([BookingStatus.PENDING, BookingStatus.CONFIRMED]),
            Booking.start_time < end_time,
            Booking.end_time > start_time,
        )
        .with_for_update()  # row-level lock — blocks concurrent transactions
    )
    if exclude_booking_id:
        stmt = stmt.where(Booking.id != exclude_booking_id)

    result = await db.execute(stmt)
    if result.scalars().first():
        raise SlotAlreadyBookedError("This slot is already booked.")

    # Check booking locks (pending payment by another user)
    now = datetime.utcnow()
    lock_stmt = (
        select(BookingLock)
        .where(
            BookingLock.ground_id == ground_id,
            BookingLock.booking_date == booking_date,
            BookingLock.start_time < end_time,
            BookingLock.end_time > start_time,
            BookingLock.expires_at > now,
        )
        .with_for_update()
    )
    lock_result = await db.execute(lock_stmt)
    if lock_result.scalars().first():
        raise SlotLockedError("This slot is temporarily reserved. Please try again in a few minutes.")


async def _validate_booking_constraints(
    db: AsyncSession,
    ground: FutsalGround,
    booking_date: date,
    start_time: time,
    end_time: time,
) -> None:
    """Validate ground is open, not closed, and times are within operating hours."""
    # Check ground closure
    closure_result = await db.execute(
        select(GroundClosure).where(
            GroundClosure.ground_id == ground.id,
            GroundClosure.start_date <= booking_date,
            GroundClosure.end_date >= booking_date,
        )
    )
    if closure_result.scalars().first():
        raise GroundClosedError(f"Ground is closed on {booking_date}.")

    # Check operating hours
    if start_time < ground.open_time or end_time > ground.close_time:
        raise OutsideOperatingHoursError(
            f"Booking must be within operating hours {ground.open_time}–{ground.close_time}."
        )

    if start_time >= end_time:
        raise ValueError("Start time must be before end time.")


def _compute_price(
    ground: FutsalGround,
    booking_date: date,
    start_time: time,
    end_time: time,
    loyalty_discount: float = 0.0,
) -> float:
    """Compute booking price with weekend + peak-hour pricing."""
    from src.apps.futsal.services.slot_service import _is_weekend, _is_peak_hour
    duration_hours = (
        datetime.combine(booking_date, end_time) - datetime.combine(booking_date, start_time)
    ).seconds / 3600

    is_wknd = _is_weekend(booking_date)
    if is_wknd and ground.weekend_price_per_hour:
        base = ground.weekend_price_per_hour
    else:
        base = ground.price_per_hour

    if _is_peak_hour(start_time, ground.peak_hours_start, ground.peak_hours_end):
        base *= ground.peak_price_multiplier

    return max(0.0, round(base * duration_hours - loyalty_discount, 2))


async def create_booking(
    db: AsyncSession,
    ground: FutsalGround,
    user_id: int,
    data: BookingCreate,
    loyalty_discount: float = 0.0,
) -> Booking:
    """
    Atomically create a booking.
    Uses SELECT FOR UPDATE to prevent double-booking race conditions.
    """
    await _validate_booking_constraints(db, ground, data.booking_date, data.start_time, data.end_time)
    await _check_slot_available(db, ground.id, data.booking_date, data.start_time, data.end_time)

    total = _compute_price(ground, data.booking_date, data.start_time, data.end_time, loyalty_discount)

    booking = Booking(
        user_id=user_id,
        ground_id=ground.id,
        booking_date=data.booking_date,
        start_time=data.start_time,
        end_time=data.end_time,
        total_amount=total,
        team_name=data.team_name,
        notes=data.notes,
        is_recurring=data.is_recurring,
        recurring_type=data.recurring_type,
        recurring_end_date=data.recurring_end_date,
        status=BookingStatus.PENDING,
    )
    db.add(booking)
    await db.flush()  # get ID without committing

    # Create a booking lock so the slot is reserved during payment
    lock = BookingLock(
        ground_id=ground.id,
        booking_date=data.booking_date,
        start_time=data.start_time,
        end_time=data.end_time,
        locked_by_booking_id=booking.id,
        locked_by_user_id=user_id,
        locked_at=datetime.utcnow(),
        expires_at=datetime.utcnow() + timedelta(minutes=LOCK_TTL_MINUTES),
    )
    try:
        db.add(lock)
        await db.flush()
    except IntegrityError:
        # Another transaction sneaked in — unique constraint on slot violated
        await db.rollback()
        raise SlotLockedError("Slot just became unavailable. Please refresh and try again.")

    await db.commit()
    await db.refresh(booking)
    return booking


async def confirm_booking(db: AsyncSession, booking: Booking) -> Booking:
    """Mark booking as CONFIRMED (called after payment success)."""
    booking.status = BookingStatus.CONFIRMED
    booking.updated_at = datetime.utcnow()
    db.add(booking)

    # Remove the booking lock — slot is now hard-booked
    lock_result = await db.execute(
        select(BookingLock).where(BookingLock.locked_by_booking_id == booking.id)
    )
    lock = lock_result.scalars().first()
    if lock:
        await db.delete(lock)

    # Create payout ledger entry
    gross = booking.total_amount
    fee = round(gross * PLATFORM_FEE_PCT / 100, 2)
    ledger = PayoutLedger(
        ground_id=booking.ground_id,
        owner_id=(await db.get(FutsalGround, booking.ground_id)).owner_id,  # type: ignore
        booking_id=booking.id,
        gross_amount=gross,
        platform_fee_pct=PLATFORM_FEE_PCT,
        platform_fee=fee,
        net_amount=round(gross - fee, 2),
        settled=False,
    )
    db.add(ledger)

    await db.commit()
    await db.refresh(booking)

    analytics.track(
        distinct_id=str(booking.user_id),
        event="booking_confirmed",
        properties={
            "booking_id": booking.id,
            "ground_id": booking.ground_id,
            "amount": booking.total_amount,
            "booking_date": str(booking.booking_date),
        },
    )
    return booking


async def cancel_booking(
    db: AsyncSession,
    booking: Booking,
    user_id: int,
    reason: Optional[str] = None,
    is_owner: bool = False,
) -> Booking:
    """
    Cancel a booking. Enforces 2-hour grace period for users (owners can cancel anytime).
    """
    if booking.status not in [BookingStatus.PENDING, BookingStatus.CONFIRMED]:
        raise BookingNotEligibleForCancelError("Only PENDING or CONFIRMED bookings can be cancelled.")

    if not is_owner:
        # Check 2-hour cancellation grace window
        booking_datetime = datetime.combine(booking.booking_date, booking.start_time)
        if datetime.utcnow() > booking_datetime - timedelta(hours=CANCELLATION_GRACE_HOURS):
            raise BookingNotEligibleForCancelError(
                "Cancellation is only allowed up to 2 hours before the match."
            )

    booking.status = BookingStatus.CANCELLED
    booking.cancellation_reason = reason
    booking.cancelled_at = datetime.utcnow()
    booking.updated_at = datetime.utcnow()
    db.add(booking)

    # Remove any payout ledger entry (unsettled only)
    ledger_result = await db.execute(
        select(PayoutLedger).where(
            PayoutLedger.booking_id == booking.id,
            PayoutLedger.settled == False,
        )
    )
    ledger = ledger_result.scalars().first()
    if ledger:
        await db.delete(ledger)

    await db.commit()
    await db.refresh(booking)

    analytics.track(
        distinct_id=str(user_id),
        event="booking_cancelled",
        properties={
            "booking_id": booking.id,
            "ground_id": booking.ground_id,
            "reason": reason,
            "cancelled_by_owner": is_owner,
        },
    )
    return booking


async def complete_booking(db: AsyncSession, booking: Booking) -> Booking:
    """Mark booking COMPLETED (called by Celery task or QR check-in)."""
    booking.status = BookingStatus.COMPLETED
    booking.updated_at = datetime.utcnow()
    db.add(booking)
    await db.commit()
    await db.refresh(booking)
    return booking
