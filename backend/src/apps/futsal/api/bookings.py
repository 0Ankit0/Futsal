"""
Bookings API: create, cancel, list, QR check-in.
Uses SELECT FOR UPDATE to prevent simultaneous booking race conditions.
"""
import io
from datetime import date
from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.schemas import BookingCreate, BookingResponse
from src.apps.futsal.services.booking_service import (
    create_booking, cancel_booking, complete_booking,
    SlotAlreadyBookedError, SlotLockedError, GroundClosedError, OutsideOperatingHoursError,
    BookingNotEligibleForCancelError,
)
from src.apps.futsal.services.loyalty_service import redeem_points, earn_points
import qrcode

router = APIRouter(tags=["Bookings"])


async def _get_booking_or_404(db: AsyncSession, booking_id: int) -> Booking:
    booking = await db.get(Booking, booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found.")
    return booking


# ──────────────────────────────────────────────────────────────────────────────
# User booking endpoints
# ──────────────────────────────────────────────────────────────────────────────

@router.post("/bookings", response_model=BookingResponse, status_code=status.HTTP_201_CREATED)
async def create_new_booking(
    data: BookingCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Create a booking with atomic slot locking (SELECT FOR UPDATE)."""
    ground = await db.get(FutsalGround, data.ground_id)
    if not ground or not ground.is_active:
        raise HTTPException(status_code=404, detail="Ground not found or inactive.")

    # Handle loyalty point redemption
    loyalty_discount = 0.0
    if data.loyalty_points_to_redeem > 0:
        try:
            loyalty_discount = await redeem_points(db, current_user.id, data.loyalty_points_to_redeem)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

    try:
        booking = await create_booking(db, ground, current_user.id, data, loyalty_discount)
    except SlotAlreadyBookedError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except SlotLockedError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except GroundClosedError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except OutsideOperatingHoursError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

    return booking


@router.get("/bookings", response_model=List[BookingResponse])
async def list_my_bookings(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    status_filter: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    stmt = select(Booking).where(Booking.user_id == current_user.id)
    if status_filter:
        stmt = stmt.where(Booking.status == status_filter)
    stmt = stmt.order_by(Booking.booking_date.desc()).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/bookings/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    booking = await _get_booking_or_404(db, booking_id)
    # Allow user, ground owner, or superuser
    ground = await db.get(FutsalGround, booking.ground_id)
    if (booking.user_id != current_user.id
            and not current_user.is_superuser
            and (ground and ground.owner_id != current_user.id)):
        raise HTTPException(status_code=403, detail="Not authorized.")
    return booking


@router.patch("/bookings/{booking_id}/cancel", response_model=BookingResponse)
async def cancel_my_booking(
    booking_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    reason: Optional[str] = None,
):
    booking = await _get_booking_or_404(db, booking_id)
    ground = await db.get(FutsalGround, booking.ground_id)
    is_owner = ground and ground.owner_id == current_user.id
    if booking.user_id != current_user.id and not is_owner and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    try:
        booking = await cancel_booking(db, booking, current_user.id, reason, is_owner=bool(is_owner))
    except BookingNotEligibleForCancelError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return booking


@router.get("/bookings/{booking_id}/qr")
async def get_booking_qr(
    booking_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Return QR code image (PNG) for the booking."""
    booking = await _get_booking_or_404(db, booking_id)
    if booking.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    if booking.status not in [BookingStatus.CONFIRMED, BookingStatus.PENDING]:
        raise HTTPException(status_code=400, detail="QR only available for active bookings.")

    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    qr.add_data(booking.qr_code)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    buf.seek(0)
    return StreamingResponse(buf, media_type="image/png")


@router.post("/bookings/{booking_id}/checkin", response_model=BookingResponse)
async def checkin_booking(
    booking_id: int,
    qr_token: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Ground owner scans QR code to check in a player."""
    booking = await _get_booking_or_404(db, booking_id)
    ground = await db.get(FutsalGround, booking.ground_id)
    if not ground or ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    if booking.qr_code != qr_token:
        raise HTTPException(status_code=400, detail="Invalid QR code.")
    if booking.qr_used:
        raise HTTPException(status_code=400, detail="QR code already used.")
    if booking.status != BookingStatus.CONFIRMED:
        raise HTTPException(status_code=400, detail="Booking is not confirmed.")

    booking.qr_used = True
    booking = await complete_booking(db, booking)

    # Earn loyalty points on check-in
    await earn_points(db, booking.user_id, booking.id, booking.total_amount)
    await db.commit()

    return booking


# ──────────────────────────────────────────────────────────────────────────────
# Owner: view bookings for their grounds
# ──────────────────────────────────────────────────────────────────────────────

@router.get("/grounds/{ground_id}/bookings", response_model=List[BookingResponse])
async def list_ground_bookings(
    ground_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    booking_date: Optional[date] = Query(None),
    status_filter: Optional[str] = Query(None),
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
):
    ground = await db.get(FutsalGround, ground_id)
    if not ground:
        raise HTTPException(status_code=404, detail="Ground not found.")
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")

    stmt = select(Booking).where(Booking.ground_id == ground_id)
    if booking_date:
        stmt = stmt.where(Booking.booking_date == booking_date)
    if status_filter:
        stmt = stmt.where(Booking.status == status_filter)
    stmt = stmt.order_by(Booking.booking_date.desc(), Booking.start_time).offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()
