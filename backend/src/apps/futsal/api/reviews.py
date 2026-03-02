"""Reviews API: CRUD + owner reply."""
from typing import Annotated, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from datetime import datetime

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.futsal.models.ground import FutsalGround
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.review import Review
from src.apps.futsal.schemas import ReviewCreate, ReviewResponse, OwnerReplyCreate

router = APIRouter(tags=["Reviews"])


@router.get("/grounds/{ground_id}/reviews", response_model=List[ReviewResponse])
async def list_reviews(ground_id: int, db: Annotated[AsyncSession, Depends(get_db)]):
    result = await db.execute(
        select(Review).where(Review.ground_id == ground_id)
        .order_by(Review.created_at.desc())
    )
    return result.scalars().all()


@router.post("/grounds/{ground_id}/reviews", response_model=ReviewResponse,
             status_code=status.HTTP_201_CREATED)
async def create_review(
    ground_id: int,
    data: ReviewCreate,
    booking_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """User can only review a ground if they have a COMPLETED booking there."""
    # Verify booking eligibility
    booking = await db.get(Booking, booking_id)
    if not booking or booking.user_id != current_user.id or booking.ground_id != ground_id:
        raise HTTPException(status_code=400, detail="Invalid booking.")
    if booking.status != BookingStatus.COMPLETED:
        raise HTTPException(status_code=400, detail="You can only review after completing a booking.")

    # Check duplicate review
    existing = await db.execute(
        select(Review).where(Review.booking_id == booking_id)
    )
    if existing.scalars().first():
        raise HTTPException(status_code=409, detail="You already reviewed this booking.")

    review = Review(
        user_id=current_user.id,
        ground_id=ground_id,
        booking_id=booking_id,
        **data.model_dump(),
        is_verified=True,
    )
    db.add(review)

    # Update ground's average rating
    ground = await db.get(FutsalGround, ground_id)
    if ground:
        total = ground.average_rating * ground.rating_count + data.rating
        ground.rating_count += 1
        ground.average_rating = round(total / ground.rating_count, 2)
        db.add(ground)

    await db.commit()
    await db.refresh(review)
    return review


@router.put("/reviews/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: int,
    data: ReviewCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found.")
    if review.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized.")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(review, k, v)
    review.updated_at = datetime.utcnow()
    db.add(review)
    await db.commit()
    await db.refresh(review)
    return review


@router.delete("/reviews/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found.")
    if review.user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Not authorized.")
    await db.delete(review)
    await db.commit()


@router.post("/reviews/{review_id}/reply", response_model=ReviewResponse)
async def owner_reply(
    review_id: int,
    data: OwnerReplyCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Ground owner replies to a review."""
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=404, detail="Review not found.")
    ground = await db.get(FutsalGround, review.ground_id)
    if not ground or ground.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized.")
    review.owner_reply = data.reply
    review.owner_replied_at = datetime.utcnow()
    db.add(review)
    await db.commit()
    await db.refresh(review)
    return review
