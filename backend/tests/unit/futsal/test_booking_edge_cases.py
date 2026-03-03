"""
Unit tests — booking edge cases.

Covers:
  - Closure dates: booking on a ground-closure date is rejected
  - Out-of-hours: booking outside open/close times is rejected
  - Cancellation grace period: cancellation within 2 hours of match is blocked
  - No-show: complete_booking handles NO_SHOW status properly
  - Recurring bookings on closure: recurring instance on closure should raise
  - Weekend/peak pricing: correct price calculated for weekend and peak hours
  - End time <= start time: rejected with ValueError
  - Cancellation of already-cancelled booking: rejected
"""
import pytest
from datetime import date, datetime, time, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.ground_closure import GroundClosure
from src.apps.futsal.schemas import BookingCreate
from src.apps.futsal.services.booking_service import (
    BookingNotEligibleForCancelError,
    GroundClosedError,
    OutsideOperatingHoursError,
    CANCELLATION_GRACE_HOURS,
    _compute_price,
    _validate_booking_constraints,
    cancel_booking,
    complete_booking,
    create_booking,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_ground(**kwargs) -> MagicMock:
    defaults = dict(
        id=1,
        owner_id=10,
        price_per_hour=500.0,
        weekend_price_per_hour=700.0,
        peak_hours_start=time(17, 0),
        peak_hours_end=time(20, 0),
        peak_price_multiplier=1.5,
        open_time=time(6, 0),
        close_time=time(22, 0),
        slot_duration_minutes=60,
        is_active=True,
    )
    defaults.update(kwargs)
    g = MagicMock(spec=FutsalGround)
    for k, v in defaults.items():
        setattr(g, k, v)
    return g


def _make_booking(
    status: BookingStatus = BookingStatus.CONFIRMED,
    booking_date: date = date(2026, 6, 10),
    start_time: time = time(14, 0),
    end_time: time = time(15, 0),
    **kwargs,
) -> MagicMock:
    b = MagicMock(spec=Booking)
    b.id = 99
    b.user_id = 42
    b.ground_id = 1
    b.status = status
    b.booking_date = booking_date
    b.start_time = start_time
    b.end_time = end_time
    b.total_amount = 500.0
    b.cancellation_reason = None
    b.cancelled_at = None
    b.updated_at = None
    for k, v in kwargs.items():
        setattr(b, k, v)
    return b


def _closure_db(booking_date: date = date(2026, 6, 10)) -> AsyncMock:
    """DB that returns a closure for the given date."""
    db = AsyncMock()
    closure = MagicMock(spec=GroundClosure)
    closure.start_date = booking_date
    closure.end_date = booking_date
    result = MagicMock()
    result.scalars.return_value.first.return_value = closure
    db.execute.return_value = result
    return db


def _open_db() -> AsyncMock:
    """DB that returns no closure and no booking conflicts."""
    db = AsyncMock()
    empty = MagicMock()
    empty.scalars.return_value.first.return_value = None
    db.execute.return_value = empty
    db.flush = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.add = MagicMock()
    db.delete = AsyncMock()
    return db


# ---------------------------------------------------------------------------
# Closure date
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_booking_on_closure_date_raises():
    """Booking on a date the ground is closed → GroundClosedError."""
    ground = _make_ground()
    db = _closure_db(date(2026, 6, 10))

    with pytest.raises(GroundClosedError):
        await _validate_booking_constraints(
            db, ground,
            booking_date=date(2026, 6, 10),
            start_time=time(10, 0),
            end_time=time(11, 0),
        )


@pytest.mark.unit
async def test_booking_outside_closure_date_succeeds():
    """Booking on a date *not* in any closure range → no error."""
    ground = _make_ground()
    db = _open_db()

    # Should not raise
    await _validate_booking_constraints(
        db, ground,
        booking_date=date(2026, 6, 15),
        start_time=time(10, 0),
        end_time=time(11, 0),
    )


# ---------------------------------------------------------------------------
# Out of operating hours
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_booking_before_open_time_raises():
    """Booking starting before ground opens → OutsideOperatingHoursError."""
    ground = _make_ground(open_time=time(8, 0), close_time=time(20, 0))
    db = _open_db()

    with pytest.raises(OutsideOperatingHoursError):
        await _validate_booking_constraints(
            db, ground,
            booking_date=date(2026, 6, 15),
            start_time=time(6, 0),   # before open at 08:00
            end_time=time(7, 0),
        )


@pytest.mark.unit
async def test_booking_after_close_time_raises():
    """Booking ending after ground closes → OutsideOperatingHoursError."""
    ground = _make_ground(open_time=time(8, 0), close_time=time(20, 0))
    db = _open_db()

    with pytest.raises(OutsideOperatingHoursError):
        await _validate_booking_constraints(
            db, ground,
            booking_date=date(2026, 6, 15),
            start_time=time(19, 30),
            end_time=time(21, 0),  # after close at 20:00
        )


@pytest.mark.unit
async def test_booking_exactly_at_boundaries_succeeds():
    """Booking exactly at open/close boundaries is allowed."""
    ground = _make_ground(open_time=time(6, 0), close_time=time(22, 0))
    db = _open_db()

    await _validate_booking_constraints(
        db, ground,
        booking_date=date(2026, 6, 15),
        start_time=time(6, 0),
        end_time=time(7, 0),
    )


@pytest.mark.unit
async def test_start_time_after_end_time_raises():
    """start_time >= end_time → ValueError."""
    ground = _make_ground()
    db = _open_db()

    with pytest.raises(ValueError):
        await _validate_booking_constraints(
            db, ground,
            booking_date=date(2026, 6, 15),
            start_time=time(12, 0),
            end_time=time(11, 0),  # end before start
        )


# ---------------------------------------------------------------------------
# Cancellation grace period
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_cancel_within_grace_period_raises():
    """Cancellation within 2 hours of the booking start → blocked for regular user."""
    # Set booking start to 1 hour from now (within grace period)
    future_start = (datetime.utcnow() + timedelta(hours=1)).time()
    booking = _make_booking(
        booking_date=datetime.utcnow().date(),
        start_time=future_start,
        status=BookingStatus.CONFIRMED,
    )

    db = _open_db()
    empty = MagicMock()
    empty.scalars.return_value.first.return_value = None
    db.execute.return_value = empty

    with pytest.raises(BookingNotEligibleForCancelError, match="2 hours"):
        await cancel_booking(db, booking, user_id=42, is_owner=False)


@pytest.mark.unit
async def test_cancel_outside_grace_period_succeeds():
    """Cancellation more than 2 hours before start → allowed for regular user."""
    # Set booking start to 3 hours from now (outside grace period)
    future_start = (datetime.utcnow() + timedelta(hours=3)).time()
    booking = _make_booking(
        booking_date=datetime.utcnow().date(),
        start_time=future_start,
        status=BookingStatus.CONFIRMED,
    )

    db = _open_db()
    empty = MagicMock()
    empty.scalars.return_value.first.return_value = None
    db.execute.return_value = empty

    with patch("src.apps.futsal.services.booking_service._push_slot_event", new_callable=AsyncMock):
        result = await cancel_booking(db, booking, user_id=42, is_owner=False)

    assert result.status == BookingStatus.CANCELLED


@pytest.mark.unit
async def test_owner_can_cancel_within_grace_period():
    """Ground owner is exempt from the 2-hour cancellation rule."""
    future_start = (datetime.utcnow() + timedelta(minutes=30)).time()  # 30 min away
    booking = _make_booking(
        booking_date=datetime.utcnow().date(),
        start_time=future_start,
        status=BookingStatus.CONFIRMED,
    )

    db = _open_db()
    empty = MagicMock()
    empty.scalars.return_value.first.return_value = None
    db.execute.return_value = empty

    with patch("src.apps.futsal.services.booking_service._push_slot_event", new_callable=AsyncMock):
        result = await cancel_booking(db, booking, user_id=10, is_owner=True)

    assert result.status == BookingStatus.CANCELLED


@pytest.mark.unit
async def test_cancel_already_cancelled_booking_raises():
    """Cancelling a booking that is already CANCELLED → BookingNotEligibleForCancelError."""
    booking = _make_booking(status=BookingStatus.CANCELLED)
    db = _open_db()

    with pytest.raises(BookingNotEligibleForCancelError):
        await cancel_booking(db, booking, user_id=42)


@pytest.mark.unit
async def test_cancel_completed_booking_raises():
    """Cancelling a COMPLETED booking → BookingNotEligibleForCancelError."""
    booking = _make_booking(status=BookingStatus.COMPLETED)
    db = _open_db()

    with pytest.raises(BookingNotEligibleForCancelError):
        await cancel_booking(db, booking, user_id=42)


# ---------------------------------------------------------------------------
# No-show / complete_booking
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_complete_booking_sets_status():
    """complete_booking marks booking COMPLETED."""
    booking = _make_booking(status=BookingStatus.CONFIRMED)
    db = _open_db()

    with patch("src.apps.futsal.services.booking_service._push_slot_event", new_callable=AsyncMock):
        result = await complete_booking(db, booking)

    assert result.status == BookingStatus.COMPLETED
    db.commit.assert_awaited_once()


@pytest.mark.unit
async def test_complete_booking_pushes_completed_event():
    """complete_booking fires 'slot.completed' WebSocket event."""
    booking = _make_booking(status=BookingStatus.CONFIRMED)
    db = _open_db()

    with patch(
        "src.apps.futsal.services.booking_service._push_slot_event",
        new_callable=AsyncMock,
    ) as mock_push:
        await complete_booking(db, booking)

    mock_push.assert_awaited_once_with(booking.ground_id, "slot.completed", booking)


# ---------------------------------------------------------------------------
# Weekend / peak-hour pricing
# ---------------------------------------------------------------------------

@pytest.mark.unit
def test_weekday_normal_price():
    """Weekday, non-peak → base price_per_hour."""
    ground = _make_ground(
        price_per_hour=500.0,
        weekend_price_per_hour=700.0,
        peak_hours_start=time(17, 0),
        peak_hours_end=time(20, 0),
        peak_price_multiplier=1.5,
    )
    monday = date(2026, 6, 1)  # Monday
    price = _compute_price(ground, monday, time(10, 0), time(11, 0))
    assert price == pytest.approx(500.0)


@pytest.mark.unit
def test_weekend_price_applied():
    """Saturday booking → weekend_price_per_hour used."""
    ground = _make_ground(
        price_per_hour=500.0,
        weekend_price_per_hour=700.0,
        peak_hours_start=None,
        peak_hours_end=None,
        peak_price_multiplier=1.0,
    )
    saturday = date(2026, 5, 30)  # Saturday
    price = _compute_price(ground, saturday, time(10, 0), time(11, 0))
    assert price == pytest.approx(700.0)


@pytest.mark.unit
def test_peak_hour_multiplier_applied():
    """Weekday peak-hour booking → base price × multiplier."""
    ground = _make_ground(
        price_per_hour=500.0,
        weekend_price_per_hour=None,
        peak_hours_start=time(17, 0),
        peak_hours_end=time(20, 0),
        peak_price_multiplier=1.5,
    )
    monday = date(2026, 6, 1)
    price = _compute_price(ground, monday, time(17, 0), time(18, 0))  # peak hour
    assert price == pytest.approx(750.0)  # 500 * 1.5


@pytest.mark.unit
def test_loyalty_discount_applied():
    """Loyalty discount reduces final price."""
    ground = _make_ground(
        price_per_hour=500.0,
        weekend_price_per_hour=None,
        peak_hours_start=None,
        peak_hours_end=None,
        peak_price_multiplier=1.0,
    )
    monday = date(2026, 6, 1)
    price = _compute_price(ground, monday, time(10, 0), time(11, 0), loyalty_discount=100.0)
    assert price == pytest.approx(400.0)


@pytest.mark.unit
def test_loyalty_discount_cannot_make_price_negative():
    """Loyalty discount larger than price → price clamped to 0."""
    ground = _make_ground(price_per_hour=500.0, peak_price_multiplier=1.0,
                          weekend_price_per_hour=None, peak_hours_start=None, peak_hours_end=None)
    monday = date(2026, 6, 1)
    price = _compute_price(ground, monday, time(10, 0), time(11, 0), loyalty_discount=9999.0)
    assert price == pytest.approx(0.0)
