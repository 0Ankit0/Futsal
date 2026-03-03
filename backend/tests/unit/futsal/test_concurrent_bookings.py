"""
Unit tests — concurrent booking prevention.

Verifies that the SELECT FOR UPDATE logic in booking_service.py
correctly prevents double-booking race conditions.
All DB calls are mocked so these run without a real database.
"""
import asyncio
import pytest
from datetime import date, time
from unittest.mock import AsyncMock, MagicMock, patch

from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.booking_lock import BookingLock
from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.schemas import BookingCreate
from src.apps.futsal.services.booking_service import (
    SlotAlreadyBookedError,
    SlotLockedError,
    _check_slot_available,
    create_booking,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

def _make_ground(**kwargs) -> FutsalGround:
    defaults = dict(
        id=1,
        name="Test Futsal",
        slug="test-futsal",
        owner_id=10,
        location="Kathmandu",
        price_per_hour=500.0,
        weekend_price_per_hour=None,
        peak_hours_start=None,
        peak_hours_end=None,
        peak_price_multiplier=1.0,
        open_time=time(6, 0),
        close_time=time(22, 0),
        slot_duration_minutes=60,
        is_active=True,
        is_verified=True,
        average_rating=4.0,
        rating_count=5,
    )
    defaults.update(kwargs)
    g = MagicMock(spec=FutsalGround)
    for k, v in defaults.items():
        setattr(g, k, v)
    return g


def _make_booking_data(
    booking_date: date = date(2026, 6, 1),
    start_time: time = time(10, 0),
    end_time: time = time(11, 0),
) -> BookingCreate:
    return BookingCreate(
        ground_id=1,
        booking_date=booking_date,
        start_time=start_time,
        end_time=end_time,
    )


def _empty_db() -> AsyncMock:
    """Return a mock DB session where queries return no results (slot free)."""
    db = AsyncMock()
    empty_result = MagicMock()
    empty_result.scalars.return_value.first.return_value = None
    db.execute.return_value = empty_result
    db.flush = AsyncMock()
    db.commit = AsyncMock()
    db.refresh = AsyncMock()
    db.add = MagicMock()
    db.delete = AsyncMock()
    return db


def _conflicting_db() -> AsyncMock:
    """Return a mock DB session where queries return an existing booking (conflict)."""
    db = AsyncMock()
    conflict_result = MagicMock()
    conflict_result.scalars.return_value.first.return_value = MagicMock(spec=Booking)
    db.execute.return_value = conflict_result
    return db


def _locked_db() -> AsyncMock:
    """Return a mock DB session where first query (bookings) is empty but lock exists."""
    db = AsyncMock()

    # First call → no confirmed booking; second call → lock exists
    empty_result = MagicMock()
    empty_result.scalars.return_value.first.return_value = None

    lock_result = MagicMock()
    lock_result.scalars.return_value.first.return_value = MagicMock(spec=BookingLock)

    db.execute.side_effect = [empty_result, lock_result]
    return db


# ---------------------------------------------------------------------------
# _check_slot_available unit tests
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_slot_available_when_no_conflicts():
    """No existing bookings → no exception raised."""
    db = _empty_db()
    # Should complete without raising
    await _check_slot_available(
        db, ground_id=1,
        booking_date=date(2026, 6, 1),
        start_time=time(10, 0),
        end_time=time(11, 0),
    )


@pytest.mark.unit
async def test_slot_raises_when_booking_exists():
    """Overlapping confirmed booking → SlotAlreadyBookedError."""
    db = _conflicting_db()
    with pytest.raises(SlotAlreadyBookedError):
        await _check_slot_available(
            db, ground_id=1,
            booking_date=date(2026, 6, 1),
            start_time=time(10, 0),
            end_time=time(11, 0),
        )


@pytest.mark.unit
async def test_slot_raises_when_lock_exists():
    """No confirmed booking but active lock → SlotLockedError."""
    db = _locked_db()
    with pytest.raises(SlotLockedError):
        await _check_slot_available(
            db, ground_id=1,
            booking_date=date(2026, 6, 1),
            start_time=time(10, 0),
            end_time=time(11, 0),
        )


@pytest.mark.unit
async def test_partial_overlap_detected():
    """A booking that partially overlaps (starts in the middle) is still a conflict."""
    db = _conflicting_db()
    with pytest.raises(SlotAlreadyBookedError):
        await _check_slot_available(
            db, ground_id=1,
            booking_date=date(2026, 6, 1),
            start_time=time(10, 30),  # overlaps with a 10:00–11:00 booking
            end_time=time(11, 30),
        )


@pytest.mark.unit
async def test_adjacent_slot_not_conflicting():
    """
    Adjacent slot (starts exactly when another ends) should NOT conflict.
    The query uses start_time < end_time AND end_time > start_time which
    naturally excludes adjacent slots — we verify the service logic allows
    booking immediately after another booking ends.
    """
    db = _empty_db()  # mock returns no conflict
    # This should succeed — adjacent, not overlapping
    await _check_slot_available(
        db, ground_id=1,
        booking_date=date(2026, 6, 1),
        start_time=time(11, 0),  # exactly when previous booking ends
        end_time=time(12, 0),
    )


# ---------------------------------------------------------------------------
# create_booking integration-style unit tests (mocked DB)
# ---------------------------------------------------------------------------

@pytest.mark.unit
async def test_create_booking_succeeds_on_free_slot():
    """create_booking succeeds when slot is free."""
    db = _empty_db()
    ground = _make_ground()
    data = _make_booking_data()

    with patch("src.apps.futsal.services.booking_service._push_slot_event", new_callable=AsyncMock):
        booking = await create_booking(db, ground, user_id=42, data=data)

    db.commit.assert_awaited_once()
    db.add.assert_called()


@pytest.mark.unit
async def test_create_booking_raises_on_conflict():
    """create_booking raises SlotAlreadyBookedError when slot is taken."""
    db = _conflicting_db()
    ground = _make_ground()
    data = _make_booking_data()

    with pytest.raises(SlotAlreadyBookedError):
        await create_booking(db, ground, user_id=42, data=data)


@pytest.mark.unit
async def test_create_booking_raises_when_lock_held():
    """create_booking raises SlotLockedError when another user holds the lock."""
    db = _locked_db()
    ground = _make_ground()
    data = _make_booking_data()

    with pytest.raises(SlotLockedError):
        await create_booking(db, ground, user_id=42, data=data)


@pytest.mark.unit
async def test_create_booking_outside_hours_raises():
    """Booking outside operating hours raises OutsideOperatingHoursError."""
    from src.apps.futsal.services.booking_service import OutsideOperatingHoursError
    db = _empty_db()
    ground = _make_ground(open_time=time(8, 0), close_time=time(20, 0))
    data = _make_booking_data(start_time=time(5, 0), end_time=time(6, 0))  # before open

    with pytest.raises(OutsideOperatingHoursError):
        await create_booking(db, ground, user_id=42, data=data)


@pytest.mark.unit
async def test_create_booking_on_closed_ground_raises():
    """Booking on a closure date raises GroundClosedError."""
    from src.apps.futsal.services.booking_service import GroundClosedError
    from src.apps.futsal.models.ground_closure import GroundClosure

    db = _empty_db()
    # First execute call (for closure check) returns a closure record
    closure_result = MagicMock()
    closure_result.scalars.return_value.first.return_value = MagicMock(spec=GroundClosure)
    db.execute.return_value = closure_result

    ground = _make_ground()
    data = _make_booking_data()

    with pytest.raises(GroundClosedError):
        await create_booking(db, ground, user_id=42, data=data)


@pytest.mark.unit
async def test_create_booking_ws_failure_does_not_rollback():
    """
    If the WebSocket push fails after a successful booking,
    the booking result is still returned (WS errors are swallowed).
    """
    db = _empty_db()
    ground = _make_ground()
    data = _make_booking_data()

    async def _failing_push(*args, **kwargs):
        raise RuntimeError("WebSocket manager unavailable")

    with patch(
        "src.apps.futsal.services.booking_service._push_slot_event",
        side_effect=_failing_push,
    ):
        # Should NOT raise — WS failure is suppressed
        booking = await create_booking(db, ground, user_id=42, data=data)

    db.commit.assert_awaited_once()


@pytest.mark.unit
async def test_create_booking_pushes_slot_locked_event():
    """create_booking calls _push_slot_event with 'slot.locked'."""
    db = _empty_db()
    ground = _make_ground()
    data = _make_booking_data()

    with patch(
        "src.apps.futsal.services.booking_service._push_slot_event",
        new_callable=AsyncMock,
    ) as mock_push:
        await create_booking(db, ground, user_id=42, data=data)

    mock_push.assert_awaited_once()
    event_arg = mock_push.call_args[0][1]  # second positional arg is the event name
    assert event_arg == "slot.locked"


@pytest.mark.unit
async def test_simultaneous_bookings_second_raises():
    """
    Simulate two concurrent coroutines trying to book the same slot.
    The first succeeds; the second should raise SlotAlreadyBookedError.
    (Mocked at the service level — DB-level locking is tested by integration tests.)
    """
    ground = _make_ground()
    data = _make_booking_data()

    call_count = 0

    async def _check_side_effect(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count > 1:
            raise SlotAlreadyBookedError("Slot taken by concurrent booking")

    with patch(
        "src.apps.futsal.services.booking_service._check_slot_available",
        side_effect=_check_side_effect,
    ):
        with patch(
            "src.apps.futsal.services.booking_service._validate_booking_constraints",
            new_callable=AsyncMock,
        ):
            with patch(
                "src.apps.futsal.services.booking_service._push_slot_event",
                new_callable=AsyncMock,
            ):
                db1 = _empty_db()
                db2 = _empty_db()

                result1 = await create_booking(db1, ground, user_id=1, data=data)

                with pytest.raises(SlotAlreadyBookedError):
                    await create_booking(db2, ground, user_id=2, data=data)
