"""Favourites and Waitlist API."""
from typing import Annotated, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from sqlalchemy.exc import IntegrityError

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.futsal.models.favourite import FavouriteGround
from src.apps.futsal.models.waitlist import WaitlistEntry
from src.apps.futsal.schemas import GroundClosureCreate
from src.apps.core.analytics import analytics

router = APIRouter(tags=["Favourites & Waitlist"])


@router.post("/favourites/{ground_id}", status_code=status.HTTP_201_CREATED)
async def toggle_favourite(
    ground_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Toggle favourite. Returns {added: true/false}."""
    existing = await db.execute(
        select(FavouriteGround).where(
            FavouriteGround.user_id == current_user.id,
            FavouriteGround.ground_id == ground_id,
        )
    )
    fav = existing.scalars().first()
    if fav:
        await db.delete(fav)
        await db.commit()
        analytics.track(
            distinct_id=str(current_user.id),
            event="ground_favourited",
            properties={"ground_id": ground_id, "action": "remove"},
        )
        return {"added": False, "ground_id": ground_id}
    try:
        fav = FavouriteGround(user_id=current_user.id, ground_id=ground_id)
        db.add(fav)
        await db.commit()
        analytics.track(
            distinct_id=str(current_user.id),
            event="ground_favourited",
            properties={"ground_id": ground_id, "action": "add"},
        )
        return {"added": True, "ground_id": ground_id}
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Already favourited.")


@router.get("/favourites", response_model=List[dict])
async def list_favourites(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    result = await db.execute(
        select(FavouriteGround).where(FavouriteGround.user_id == current_user.id)
    )
    return [{"id": f.id, "ground_id": f.ground_id, "created_at": f.created_at}
            for f in result.scalars().all()]


@router.post("/waitlist", status_code=status.HTTP_201_CREATED)
async def join_waitlist(
    entry: WaitlistEntry,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Join waitlist for a specific slot."""
    waitlist = WaitlistEntry(
        user_id=current_user.id,
        ground_id=entry.ground_id,
        booking_date=entry.booking_date,
        start_time=entry.start_time,
        end_time=entry.end_time,
    )
    db.add(waitlist)
    await db.commit()
    await db.refresh(waitlist)
    analytics.track(
        distinct_id=str(current_user.id),
        event="waitlist_joined",
        properties={
            "ground_id": waitlist.ground_id,
            "slot": f"{waitlist.booking_date}T{waitlist.start_time}",
        },
    )
    return waitlist


@router.delete("/waitlist/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
async def leave_waitlist(
    entry_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    entry = await db.get(WaitlistEntry, entry_id)
    if not entry or entry.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Waitlist entry not found.")
    await db.delete(entry)
    await db.commit()
