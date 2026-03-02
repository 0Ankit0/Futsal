"""
Celery tasks for the payout app.
- daily_payout_task: runs at midnight UTC every day
- retry_failed_payouts: retry failed payout records
"""
import asyncio
from datetime import datetime, timedelta
import logging

from src.apps.core.celery_app import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(name="payout.daily_payout", bind=True, max_retries=3)
def daily_payout_task(self):
    """Process daily payouts for all owners with verified gateways."""
    from src.db.session import async_session_factory
    from src.apps.payout.services.payout_service import process_daily_payouts

    async def _run():
        async with async_session_factory() as db:
            return await process_daily_payouts(db)

    try:
        results = asyncio.get_event_loop().run_until_complete(_run())
        logger.info(f"Daily payout completed: {results}")
        return results
    except Exception as exc:
        logger.error(f"Daily payout task failed: {exc}")
        raise self.retry(exc=exc, countdown=300)  # retry in 5 minutes


@celery_app.task(name="payout.retry_failed")
def retry_failed_payouts():
    """Re-queue FAILED payout records for another attempt."""
    from src.db.session import async_session_factory
    from src.apps.payout.models.payout_record import PayoutRecord, PayoutStatus
    from sqlmodel import select

    async def _run():
        async with async_session_factory() as db:
            result = await db.execute(
                select(PayoutRecord).where(PayoutRecord.status == PayoutStatus.FAILED)
            )
            records = result.scalars().all()
            from src.apps.payout.services.payout_service import _call_gateway, MAX_RETRIES
            from src.apps.payout.models.owner_gateway import OwnerPaymentGateway
            for record in records:
                gw = await db.execute(
                    select(OwnerPaymentGateway).where(
                        OwnerPaymentGateway.owner_id == record.owner_id,
                        OwnerPaymentGateway.is_active == True,
                        OwnerPaymentGateway.is_verified == True,
                    )
                )
                gateway = gw.scalars().first()
                if not gateway:
                    continue
                success, ref = await _call_gateway(gateway, record.net_amount)
                if success:
                    record.status = PayoutStatus.COMPLETED
                    record.transaction_ref = ref
                    record.completed_at = datetime.utcnow()
                    from src.apps.payout.models.payout_ledger import PayoutLedger
                    ledgers = await db.execute(
                        select(PayoutLedger).where(PayoutLedger.payout_id == record.id)
                    )
                    for ledger in ledgers.scalars().all():
                        ledger.settled = True
                        db.add(ledger)
                else:
                    record.retry_count += 1
                    record.last_error = ref
                    if record.retry_count >= MAX_RETRIES:
                        record.status = PayoutStatus.ON_HOLD
                db.add(record)
            await db.commit()

    asyncio.get_event_loop().run_until_complete(_run())


# Celery Beat schedule — midnight UTC daily payout
celery_app.conf.beat_schedule = {
    "daily-payout-midnight": {
        "task": "payout.daily_payout",
        "schedule": celery_app.conf.get("CELERY_BEAT_SCHEDULE", {}).get(
            "daily-payout-midnight", {}).get("schedule", None) or
            # crontab at 00:00 UTC
            __import__("celery.schedules", fromlist=["crontab"]).crontab(hour=0, minute=0),
    },
    "retry-failed-payouts": {
        "task": "payout.retry_failed",
        "schedule": __import__(
            "celery.schedules", fromlist=["crontab"]
        ).crontab(hour="*/4", minute=0),  # every 4 hours
    },
}
