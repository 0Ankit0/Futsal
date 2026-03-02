"""
Daily payout service.

PAYOUT_MODE = "PLATFORM"  (default)
  Money from player bookings lands in the platform's own merchant account
  (credentials in .env PLATFORM_KHALTI_* / PLATFORM_ESEWA_* etc.).
  The midnight Celery job transfers the net amount from platform → each owner's
  configured payment gateway.

PAYOUT_MODE = "DIRECT"
  Player payments go directly into the owner's own merchant account.
  The midnight job just marks ledger entries as settled and creates a
  PayoutRecord for audit — no actual money movement happens here.

Switch by setting PAYOUT_MODE in your .env file.
"""
from datetime import date, datetime
from enum import Enum
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
import httpx
import logging

from src.apps.core.config import settings
from src.apps.payout.models.payout_record import PayoutRecord, PayoutStatus
from src.apps.payout.models.payout_ledger import PayoutLedger
from src.apps.payout.models.owner_gateway import OwnerPaymentGateway, GatewayProvider
from src.apps.payout.services.encryption import decrypt_credentials
from src.apps.core.analytics import analytics

logger = logging.getLogger(__name__)

MAX_RETRIES = 3


class PayoutMode(str, Enum):
    PLATFORM = "PLATFORM"  # platform collects, then pushes to owners
    DIRECT   = "DIRECT"    # owner's merchant receives payment directly


def get_payout_mode() -> PayoutMode:
    """Read current payout mode from settings."""
    raw = (settings.PAYOUT_MODE or "PLATFORM").upper().strip()
    try:
        return PayoutMode(raw)
    except ValueError:
        logger.warning(f"Unknown PAYOUT_MODE '{raw}', defaulting to PLATFORM.")
        return PayoutMode.PLATFORM


# ── Main entry point ──────────────────────────────────────────────────────────

async def process_daily_payouts(db: AsyncSession) -> dict:
    """
    Called by Celery Beat at midnight.
    Behaviour depends on PAYOUT_MODE env var.
    """
    mode = get_payout_mode()
    today = date.today()
    results = {"mode": mode.value, "processed": 0, "failed": 0, "on_hold": 0, "direct_settled": 0}

    from src.apps.futsal.models.booking import Booking, BookingStatus

    stmt = (
        select(PayoutLedger, Booking)
        .join(Booking, PayoutLedger.booking_id == Booking.id)
        .where(
            PayoutLedger.settled == False,
            Booking.status == BookingStatus.COMPLETED,
            Booking.booking_date < today,
        )
    )
    rows = (await db.execute(stmt)).all()

    if not rows:
        logger.info("No unsettled ledger entries found.")
        return results

    # Group by owner_id
    by_owner: dict[int, list[PayoutLedger]] = {}
    for ledger, _ in rows:
        by_owner.setdefault(ledger.owner_id, []).append(ledger)

    for owner_id, entries in by_owner.items():
        if mode == PayoutMode.DIRECT:
            await _settle_direct(db, owner_id, entries, today, results)
        else:
            await _process_platform_payout(db, owner_id, entries, today, results)

    return results


# ── DIRECT mode ───────────────────────────────────────────────────────────────

async def _settle_direct(
    db: AsyncSession,
    owner_id: int,
    entries: list[PayoutLedger],
    payout_date: date,
    results: dict,
) -> None:
    """
    DIRECT mode: money is already in owner's account.
    Just mark ledger settled and write an audit PayoutRecord.
    """
    gross = sum(e.gross_amount for e in entries)
    fee   = sum(e.platform_fee for e in entries)
    net   = sum(e.net_amount for e in entries)

    record = PayoutRecord(
        owner_id=owner_id,
        period_start=payout_date,
        period_end=payout_date,
        total_bookings=len(entries),
        gross_amount=gross,
        platform_fee_pct=entries[0].platform_fee_pct,
        platform_fee=fee,
        net_amount=net,
        currency="NPR",
        status=PayoutStatus.COMPLETED,   # no transfer needed
        payout_mode=PayoutMode.DIRECT.value,
        provider="DIRECT",
        transaction_ref="DIRECT-SETTLED",
        initiated_at=datetime.utcnow(),
        completed_at=datetime.utcnow(),
    )
    db.add(record)
    await db.flush()

    for entry in entries:
        entry.settled = True
        entry.payout_mode = PayoutMode.DIRECT.value
        entry.payout_id = record.id
        db.add(entry)

    await db.commit()
    results["direct_settled"] += 1
    logger.info(f"[DIRECT] Owner {owner_id}: {len(entries)} entries settled (NPR {net} already in owner account).")


# ── PLATFORM mode ─────────────────────────────────────────────────────────────

async def _process_platform_payout(
    db: AsyncSession,
    owner_id: int,
    entries: list[PayoutLedger],
    payout_date: date,
    results: dict,
) -> None:
    """
    PLATFORM mode: platform collected the money; now transfer net amount to owner.
    Uses owner's configured and verified payment gateway.
    """
    gross = sum(e.gross_amount for e in entries)
    fee   = sum(e.platform_fee for e in entries)
    net   = sum(e.net_amount for e in entries)

    gw_result = await db.execute(
        select(OwnerPaymentGateway).where(
            OwnerPaymentGateway.owner_id == owner_id,
            OwnerPaymentGateway.is_active == True,
            OwnerPaymentGateway.is_verified == True,
        )
    )
    gateway = gw_result.scalars().first()

    if not gateway:
        logger.warning(f"[PLATFORM] Owner {owner_id} has no verified active gateway. Putting on hold.")
        results["on_hold"] += 1
        # Create an ON_HOLD record so superuser can see it
        db.add(PayoutRecord(
            owner_id=owner_id,
            period_start=payout_date,
            period_end=payout_date,
            total_bookings=len(entries),
            gross_amount=gross,
            platform_fee_pct=entries[0].platform_fee_pct,
            platform_fee=fee,
            net_amount=net,
            currency="NPR",
            status=PayoutStatus.ON_HOLD,
            payout_mode=PayoutMode.PLATFORM.value,
            last_error="No verified payment gateway configured.",
            initiated_at=datetime.utcnow(),
        ))
        await db.commit()
        return

    record = PayoutRecord(
        owner_id=owner_id,
        period_start=payout_date,
        period_end=payout_date,
        total_bookings=len(entries),
        gross_amount=gross,
        platform_fee_pct=entries[0].platform_fee_pct,
        platform_fee=fee,
        net_amount=net,
        currency="NPR",
        status=PayoutStatus.PROCESSING,
        payout_mode=PayoutMode.PLATFORM.value,
        provider=gateway.provider.value,
        initiated_at=datetime.utcnow(),
    )
    db.add(record)
    await db.flush()

    success, ref_or_error = await _call_gateway(gateway, net)

    if success:
        record.status = PayoutStatus.COMPLETED
        record.transaction_ref = ref_or_error
        record.completed_at = datetime.utcnow()
        for entry in entries:
            entry.settled = True
            entry.payout_mode = PayoutMode.PLATFORM.value
            entry.payout_id = record.id
            db.add(entry)
        results["processed"] += 1
        logger.info(f"[PLATFORM] Payout {record.id} completed for owner {owner_id}: NPR {net}")
        analytics.track(
            distinct_id=str(owner_id),
            event="payout_processed",
            properties={
                "payout_id": record.id,
                "net_amount": net,
                "gross_amount": gross,
                "mode": PayoutMode.PLATFORM.value,
                "provider": gateway.provider.value,
                "bookings_count": len(entries),
            },
        )
    else:
        record.retry_count += 1
        record.last_error = ref_or_error
        if record.retry_count >= MAX_RETRIES:
            record.status = PayoutStatus.ON_HOLD
            results["on_hold"] += 1
            logger.error(f"[PLATFORM] Payout {record.id} ON_HOLD for owner {owner_id} after {MAX_RETRIES} retries.")
        else:
            record.status = PayoutStatus.FAILED
            results["failed"] += 1
            logger.warning(f"[PLATFORM] Payout {record.id} failed (attempt {record.retry_count}) for owner {owner_id}.")

    db.add(record)
    await db.commit()


# ── Gateway dispatch ──────────────────────────────────────────────────────────
# These functions transfer money FROM the platform's merchant account TO the owner.

async def _call_gateway(gateway: OwnerPaymentGateway, amount: float) -> tuple[bool, str]:
    """Dispatch to the correct provider. Returns (success, ref_or_error)."""
    try:
        creds = decrypt_credentials(gateway.credentials_encrypted)
        if gateway.provider == GatewayProvider.KHALTI:
            return await _khalti_payout(creds, amount)
        elif gateway.provider == GatewayProvider.ESEWA:
            return await _esewa_payout(creds, amount)
        elif gateway.provider == GatewayProvider.BANK_TRANSFER:
            return await _bank_transfer_payout(creds, amount)
        else:
            return False, f"Unsupported provider: {gateway.provider}"
    except Exception as e:
        logger.exception("Gateway call raised an exception")
        return False, str(e)


async def _khalti_payout(creds: dict, amount: float) -> tuple[bool, str]:
    """
    Platform sends to owner's Khalti wallet.
    Uses PLATFORM_KHALTI_SECRET_KEY (platform merchant) as the sender.
    creds = owner's decrypted credentials (contains owner's mobile or wallet ID).
    """
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            "https://khalti.com/api/v2/merchant/transfer/",
            headers={"Authorization": f"Key {settings.PLATFORM_KHALTI_SECRET_KEY}"},
            json={
                "amount": int(amount * 100),  # paisa
                "mobile": creds.get("mobile"),
                "remarks": "FutsalApp ground booking payout",
            },
        )
        if resp.status_code == 200:
            return True, resp.json().get("transaction_id", "")
        return False, f"Khalti error {resp.status_code}: {resp.text[:200]}"


async def _esewa_payout(creds: dict, amount: float) -> tuple[bool, str]:
    """
    Platform sends to owner's eSewa wallet.
    Uses PLATFORM_ESEWA_MERCHANT_CODE / PLATFORM_ESEWA_SECRET_KEY as sender.
    """
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            "https://esewa.com.np/epay/transrec",
            data={
                "scd": settings.PLATFORM_ESEWA_MERCHANT_CODE,
                "rid": creds.get("account_id"),    # owner's eSewa ID
                "amt": amount,
            },
        )
        return resp.status_code == 200, resp.text[:200]


async def _bank_transfer_payout(creds: dict, amount: float) -> tuple[bool, str]:
    """
    Bank transfer from platform account to owner's bank account.
    Logs details for manual processing (or integrate with your bank's API).
    Platform bank details come from settings; owner bank details from creds.
    """
    logger.info(
        f"[BANK TRANSFER] NPR {amount:.2f} "
        f"FROM {settings.PLATFORM_BANK_ACCOUNT_NAME} / {settings.PLATFORM_BANK_ACCOUNT_NUMBER} "
        f"TO {creds.get('account_name')} / {creds.get('account_number')} "
        f"({creds.get('bank_name')}, SWIFT: {creds.get('swift_code', 'N/A')})"
    )
    # In production: call your bank's payment API here.
    return True, f"BANK-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"


# ── Platform balance helper (for superuser dashboard) ─────────────────────────

async def get_platform_pending_balance(db: AsyncSession) -> dict:
    """
    Returns total unsettled amounts held in the platform account.
    Only meaningful in PLATFORM mode.
    """
    stmt = (
        select(PayoutLedger)
        .where(
            PayoutLedger.settled == False,
            PayoutLedger.payout_mode == PayoutMode.PLATFORM.value,
        )
    )
    entries = (await db.execute(stmt)).scalars().all()
    total_gross = sum(e.gross_amount for e in entries)
    total_fee   = sum(e.platform_fee for e in entries)
    total_net   = sum(e.net_amount for e in entries)
    return {
        "payout_mode": get_payout_mode().value,
        "unsettled_entries": len(entries),
        "total_gross_npr": total_gross,
        "total_platform_fee_npr": total_fee,
        "total_owed_to_owners_npr": total_net,
    }
