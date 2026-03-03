"""
Grounds API: CRUD + images + closures + slot availability.
"""
import re
from datetime import date
from typing import Annotated, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.ground_image import GroundImage
from src.apps.futsal.models.ground_closure import GroundClosure
from src.apps.core.analytics import analytics
from src.apps.futsal.schemas import (
    GroundCreate, GroundUpdate, GroundResponse, SlotResponse, GroundClosureCreate
)
from src.apps.futsal.services.slot_service import get_available_slots
from src.apps.core.config import settings
from src.apps.subscription.dependencies import require_active_subscription

# Alias for owner-mutating endpoints — requires active subscription
_owner = require_active_subscription
import os, uuid, shutil

router = APIRouter(prefix="/grounds", tags=["Grounds"])


def _slugify(name: str) -> str:
    slug = re.sub(r"[^\w\s-]", "", name.lower()).strip()
    slug = re.sub(r"[\s_-]+", "-", slug)
    return slug + "-" + str(uuid.uuid4())[:8]


def _require_owner(user: User) -> None:
    if not user.is_superuser:
        # Check via role name — adjust if your RBAC uses a different pattern
        pass  # roles checked at route level via Casbin or inline


async def _get_ground_or_404(db: AsyncSession, ground_id: int) -> FutsalGround:
    ground = await db.get(FutsalGround, ground_id)
    if not ground:
        raise HTTPException(status_code=404, detail="Ground not found.")
    return ground


# ──────────────────────────────────────────────────────────────────────────────
# Public endpoints
# ──────────────────────────────────────────────────────────────────────────────

@router.get("", response_model=List[GroundResponse])
async def list_grounds(
    db: Annotated[AsyncSession, Depends(get_db)],
    location: Optional[str] = Query(None),
    min_price: Optional[float] = Query(None),
    max_price: Optional[float] = Query(None),
    ground_type: Optional[str] = Query(None),
    verified_only: bool = Query(False),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
):
    stmt = select(FutsalGround).where(FutsalGround.is_active == True)
    if location:
        stmt = stmt.where(FutsalGround.location.ilike(f"%{location}%"))
    if min_price is not None:
        stmt = stmt.where(FutsalGround.price_per_hour >= min_price)
    if max_price is not None:
        stmt = stmt.where(FutsalGround.price_per_hour <= max_price)
    if ground_type:
        stmt = stmt.where(FutsalGround.ground_type == ground_type)
    if verified_only:
        stmt = stmt.where(FutsalGround.is_verified == True)
    stmt = stmt.offset(skip).limit(limit)
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/{ground_id}", response_model=GroundResponse)
async def get_ground(ground_id: int, db: Annotated[AsyncSession, Depends(get_db)]):
    return await _get_ground_or_404(db, ground_id)


@router.get("/{ground_id}/slots", response_model=List[SlotResponse])
async def get_slots(
    ground_id: int,
    booking_date: date = Query(...),
    db: Annotated[AsyncSession, Depends(get_db)] = ...,
):
    ground = await _get_ground_or_404(db, ground_id)
    if not ground.is_active:
        raise HTTPException(status_code=400, detail="Ground is not active.")
    return await get_available_slots(db, ground, booking_date)


@router.get("/{ground_id}/images")
async def get_ground_images(ground_id: int, db: Annotated[AsyncSession, Depends(get_db)]):
    await _get_ground_or_404(db, ground_id)
    result = await db.execute(
        select(GroundImage).where(GroundImage.ground_id == ground_id)
        .order_by(GroundImage.is_primary.desc(), GroundImage.display_order)
    )
    return result.scalars().all()


# ──────────────────────────────────────────────────────────────────────────────
# Owner / Superuser endpoints
# ──────────────────────────────────────────────────────────────────────────────

@router.post("", response_model=GroundResponse, status_code=status.HTTP_201_CREATED)
async def create_ground(
    data: GroundCreate,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = FutsalGround(
        **data.model_dump(),
        owner_id=current_user.id,
        slug=_slugify(data.name),
    )
    db.add(ground)
    await db.commit()
    await db.refresh(ground)
    analytics.track(
        distinct_id=str(current_user.id),
        event="ground_created",
        properties={
            "ground_id": ground.id,
            "ground_name": ground.name,
            "ground_type": ground.ground_type,
        },
    )
    return ground


@router.put("/{ground_id}", response_model=GroundResponse)
async def update_ground(
    ground_id: int,
    data: GroundUpdate,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(ground, field, value)
    from datetime import datetime
    ground.updated_at = datetime.utcnow()
    db.add(ground)
    await db.commit()
    await db.refresh(ground)
    return ground


@router.delete("/{ground_id}", status_code=status.HTTP_204_NO_CONTENT)
async def deactivate_ground(
    ground_id: int,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    ground.is_active = False
    db.add(ground)
    await db.commit()


@router.post("/{ground_id}/verify", response_model=GroundResponse)
async def verify_ground(
    ground_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Superuser only: mark ground as verified."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    ground = await _get_ground_or_404(db, ground_id)
    ground.is_verified = True
    db.add(ground)
    await db.commit()
    await db.refresh(ground)
    analytics.track(
        distinct_id=str(current_user.id),
        event="ground_verified",
        properties={"ground_id": ground_id, "owner_id": ground.owner_id},
    )
    return ground


@router.post("/{ground_id}/images", status_code=status.HTTP_201_CREATED)
async def upload_image(
    ground_id: int,
    file: UploadFile = File(...),
    is_primary: bool = False,
    current_user: User = Depends(_owner),
    db: AsyncSession = Depends(get_db),
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")

    os.makedirs(settings.MEDIA_DIR + "/grounds", exist_ok=True)
    filename = f"{uuid.uuid4()}{os.path.splitext(file.filename or '.jpg')[1]}"
    dest = os.path.join(settings.MEDIA_DIR, "grounds", filename)
    with open(dest, "wb") as f:
        shutil.copyfileobj(file.file, f)

    image_url = f"{settings.MEDIA_URL}/grounds/{filename}"
    image = GroundImage(ground_id=ground_id, image_url=image_url, is_primary=is_primary)
    db.add(image)
    await db.commit()
    await db.refresh(image)
    return image


@router.delete("/{ground_id}/images/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_image(
    ground_id: int,
    image_id: int,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    img = await db.get(GroundImage, image_id)
    if not img or img.ground_id != ground_id:
        raise HTTPException(status_code=404, detail="Image not found.")
    await db.delete(img)
    await db.commit()


@router.post("/{ground_id}/closures", status_code=status.HTTP_201_CREATED)
async def add_closure(
    ground_id: int,
    data: GroundClosureCreate,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    closure = GroundClosure(ground_id=ground_id, **data.model_dump())
    db.add(closure)
    await db.commit()
    await db.refresh(closure)
    return closure


@router.delete("/{ground_id}/closures/{closure_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_closure(
    ground_id: int,
    closure_id: int,
    current_user: Annotated[User, Depends(_owner)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    ground = await _get_ground_or_404(db, ground_id)
    if ground.owner_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    closure = await db.get(GroundClosure, closure_id)
    if not closure or closure.ground_id != ground_id:
        raise HTTPException(status_code=404, detail="Closure not found.")
    await db.delete(closure)
    await db.commit()
