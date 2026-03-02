"""Payout records and ledger API."""
from datetime import date
from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, SQLModel

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.payout.models.payout_record import PayoutRecord, PayoutStatus
from src.apps.payout.models.payout_ledger import PayoutLedger
from src.apps.payout.services.payout_service import get_payout_mode, get_platform_pending_balance

router = APIRouter(prefix="/payout", tags=["Payouts"])


@router.get("/history", response_model=List[PayoutRecord])
async def payout_history(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    result = await db.execute(
        select(PayoutRecord)
        .where(PayoutRecord.owner_id == current_user.id)
        .order_by(PayoutRecord.created_at.desc())
        .offset(skip).limit(limit)
    )
    return result.scalars().all()


@router.get("/ledger", response_model=List[PayoutLedger])
async def payout_ledger(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settled: Optional[bool] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
):
    stmt = select(PayoutLedger).where(PayoutLedger.owner_id == current_user.id)
    if settled is not None:
        stmt = stmt.where(PayoutLedger.settled == settled)
    stmt = stmt.order_by(PayoutLedger.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/pending-balance")
async def pending_balance(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Return unsettled net amount for the current owner."""
    result = await db.execute(
        select(PayoutLedger).where(
            PayoutLedger.owner_id == current_user.id,
            PayoutLedger.settled == False,
        )
    )
    entries = result.scalars().all()
    return {
        "pending_amount": round(sum(e.net_amount for e in entries), 2),
        "pending_bookings": len(entries),
        "currency": "NPR",
        "payout_mode": get_payout_mode().value,
    }


# ── Superuser endpoints ───────────────────────────────────────────────────────

@router.get("/mode")
async def current_payout_mode(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """
    Returns the active payout mode and what it means.
    Useful for superuser dashboard and testing.
    """
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    mode = get_payout_mode()
    return {
        "payout_mode": mode.value,
        "description": (
            "Money goes directly to each owner's merchant account. "
            "Midnight job marks ledger settled (no transfer)."
            if mode.value == "DIRECT" else
            "Money lands in the platform account first. "
            "Midnight job transfers net amount to each owner's configured gateway."
        ),
        "config_key": "PAYOUT_MODE",
        "possible_values": ["PLATFORM", "DIRECT"],
    }


@router.get("/platform-balance")
async def platform_balance(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Superuser: total unsettled funds held in the platform account.
    Only relevant in PLATFORM mode; shows what's owed to all owners tonight.
    """
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    return await get_platform_pending_balance(db)


@router.get("/records", response_model=List[PayoutRecord])
async def all_payout_records(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    status_filter: Optional[str] = Query(None),
    payout_mode: Optional[str] = Query(None, description="Filter by DIRECT or PLATFORM"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    stmt = select(PayoutRecord)
    if status_filter:
        stmt = stmt.where(PayoutRecord.status == status_filter)
    if payout_mode:
        stmt = stmt.where(PayoutRecord.payout_mode == payout_mode.upper())
    stmt = stmt.order_by(PayoutRecord.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/records/{record_id}/retry")
async def retry_payout(
    record_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    record = await db.get(PayoutRecord, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="Payout record not found.")
    if record.status not in [PayoutStatus.FAILED, PayoutStatus.ON_HOLD]:
        raise HTTPException(status_code=400, detail="Only FAILED or ON_HOLD records can be retried.")
    record.status = PayoutStatus.PENDING
    record.retry_count = 0
    record.last_error = None
    db.add(record)
    await db.commit()
    from src.apps.payout.tasks import retry_failed_payouts
    retry_failed_payouts.delay()
    return {"message": "Retry queued."}


@router.patch("/records/{record_id}/hold")
async def hold_payout(
    record_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    record = await db.get(PayoutRecord, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="Payout record not found.")
    record.status = PayoutStatus.ON_HOLD
    db.add(record)
    await db.commit()
    return {"message": "Payout put on hold."}


@router.get("/history", response_model=List[PayoutRecord])
async def payout_history(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    result = await db.execute(
        select(PayoutRecord)
        .where(PayoutRecord.owner_id == current_user.id)
        .order_by(PayoutRecord.created_at.desc())
        .offset(skip).limit(limit)
    )
    return result.scalars().all()


@router.get("/ledger", response_model=List[PayoutLedger])
async def payout_ledger(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    settled: Optional[bool] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
):
    stmt = select(PayoutLedger).where(PayoutLedger.owner_id == current_user.id)
    if settled is not None:
        stmt = stmt.where(PayoutLedger.settled == settled)
    stmt = stmt.order_by(PayoutLedger.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/pending-balance")
async def pending_balance(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Return unsettled net amount for the current owner."""
    result = await db.execute(
        select(PayoutLedger).where(
            PayoutLedger.owner_id == current_user.id,
            PayoutLedger.settled == False,
        )
    )
    entries = result.scalars().all()
    return {
        "pending_amount": round(sum(e.net_amount for e in entries), 2),
        "pending_bookings": len(entries),
        "currency": "NPR",
    }


# Superuser endpoints
@router.get("/records", response_model=List[PayoutRecord])
async def all_payout_records(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    status_filter: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    stmt = select(PayoutRecord)
    if status_filter:
        stmt = stmt.where(PayoutRecord.status == status_filter)
    stmt = stmt.order_by(PayoutRecord.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.patch("/records/{record_id}/retry")
async def retry_payout(
    record_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    record = await db.get(PayoutRecord, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="Payout record not found.")
    if record.status not in [PayoutStatus.FAILED, PayoutStatus.ON_HOLD]:
        raise HTTPException(status_code=400, detail="Only FAILED or ON_HOLD records can be retried.")
    record.status = PayoutStatus.PENDING
    record.retry_count = 0
    record.last_error = None
    db.add(record)
    await db.commit()
    # Trigger async retry task
    from src.apps.payout.tasks import retry_failed_payouts
    retry_failed_payouts.delay()
    return {"message": "Retry queued."}


@router.patch("/records/{record_id}/hold")
async def hold_payout(
    record_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    record = await db.get(PayoutRecord, record_id)
    if not record:
        raise HTTPException(status_code=404, detail="Payout record not found.")
    record.status = PayoutStatus.ON_HOLD
    db.add(record)
    await db.commit()
    return {"message": "Payout put on hold."}
