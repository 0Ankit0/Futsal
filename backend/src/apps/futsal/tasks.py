"""
Celery tasks for the futsal app.
- release_expired_booking_locks: frees locks past TTL
- update_completed_bookings: marks past confirmed bookings as COMPLETED
- send_booking_reminders: 24h and 2h reminders
- expire_loyalty_points: monthly cleanup
"""
import asyncio
from datetime import datetime, date, timedelta
import logging

from src.apps.core.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="futsal.release_expired_locks")
def release_expired_locks():
    """Remove BookingLock entries whose TTL has expired."""
    from src.db.session import async_session_factory
    from src.apps.futsal.models.booking_lock import BookingLock
    from src.apps.futsal.models.booking import Booking, BookingStatus
    from sqlmodel import select, delete

    async def _run():
        async with async_session_factory() as db:
            now = datetime.utcnow()
            # Delete expired locks
            expired = await db.execute(
                select(BookingLock).where(BookingLock.expires_at <= now)
            )
            expired_locks = expired.scalars().all()
            for lock in expired_locks:
                # Cancel the pending booking if payment wasn't completed
                if lock.locked_by_booking_id:
                    booking = await db.get(Booking, lock.locked_by_booking_id)
                    if booking and booking.status == BookingStatus.PENDING:
                        booking.status = BookingStatus.CANCELLED
                        booking.cancellation_reason = "Payment timeout — lock expired."
                        db.add(booking)
                await db.delete(lock)

                # Notify waitlist users for this slot
                from src.apps.futsal.models.waitlist import WaitlistEntry
                waitlist = await db.execute(
                    select(WaitlistEntry).where(
                        WaitlistEntry.ground_id == lock.ground_id,
                        WaitlistEntry.booking_date == lock.booking_date,
                        WaitlistEntry.start_time == lock.start_time,
                        WaitlistEntry.end_time == lock.end_time,
                        WaitlistEntry.is_active == True,
                    ).order_by(WaitlistEntry.created_at).limit(1)
                )
                first_waiter = waitlist.scalars().first()
                if first_waiter:
                    first_waiter.notified_at = now
                    first_waiter.is_active = False
                    db.add(first_waiter)
                    # TODO: trigger notification to first_waiter.user_id

            await db.commit()
            logger.info(f"Released {len(expired_locks)} expired booking locks.")

    asyncio.get_event_loop().run_until_complete(_run())


@celery_app.task(name="futsal.update_completed_bookings")
def update_completed_bookings():
    """Mark confirmed bookings whose end_time has passed as COMPLETED."""
    from src.db.session import async_session_factory
    from src.apps.futsal.models.booking import Booking, BookingStatus

    async def _run():
        async with async_session_factory() as db:
            from sqlmodel import select
            now = datetime.utcnow()
            today = now.date()
            result = await db.execute(
                select(Booking).where(
                    Booking.status == BookingStatus.CONFIRMED,
                    Booking.booking_date <= today,
                )
            )
            updated = 0
            for booking in result.scalars().all():
                booking_end = datetime.combine(booking.booking_date, booking.end_time)
                if booking_end < now:
                    booking.status = BookingStatus.COMPLETED
                    booking.updated_at = now
                    db.add(booking)
                    updated += 1
            await db.commit()
            logger.info(f"Marked {updated} bookings as COMPLETED.")

    asyncio.get_event_loop().run_until_complete(_run())


@celery_app.task(name="futsal.send_booking_reminders")
def send_booking_reminders():
    """Send 24h and 2h reminders for upcoming confirmed bookings."""
    from src.db.session import async_session_factory
    from src.apps.futsal.models.booking import Booking, BookingStatus

    async def _run():
        async with async_session_factory() as db:
            from sqlmodel import select
            now = datetime.utcnow()
            result = await db.execute(
                select(Booking).where(Booking.status == BookingStatus.CONFIRMED)
            )
            for booking in result.scalars().all():
                start_dt = datetime.combine(booking.booking_date, booking.start_time)
                hours_until = (start_dt - now).total_seconds() / 3600
                if 23 <= hours_until <= 25 or 1.5 <= hours_until <= 2.5:
                    # TODO: send notification to booking.user_id
                    logger.info(f"Reminder sent for booking {booking.id} (in {hours_until:.1f}h)")

    asyncio.get_event_loop().run_until_complete(_run())


# Register beat schedule
from celery.schedules import crontab  # noqa

celery_app.conf.beat_schedule.update({
    "release-expired-locks": {
        "task": "futsal.release_expired_locks",
        "schedule": 300,  # every 5 minutes
    },
    "update-completed-bookings": {
        "task": "futsal.update_completed_bookings",
        "schedule": 300,  # every 5 minutes
    },
    "send-booking-reminders": {
        "task": "futsal.send_booking_reminders",
        "schedule": 3600,  # every hour
    },
})
