"""Loyalty points API."""
from typing import Annotated, List
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.futsal.models.loyalty import LoyaltyAccount, LoyaltyTransaction
from src.apps.futsal.schemas import LoyaltyAccountResponse, LoyaltyTransactionResponse
from src.apps.futsal.services.loyalty_service import get_or_create_account

router = APIRouter(prefix="/loyalty", tags=["Loyalty"])


@router.get("", response_model=LoyaltyAccountResponse)
async def get_loyalty(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    account = await get_or_create_account(db, current_user.id)
    await db.commit()
    return account


@router.get("/history", response_model=List[LoyaltyTransactionResponse])
async def loyalty_history(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    skip: int = 0,
    limit: int = 50,
):
    account = await get_or_create_account(db, current_user.id)
    result = await db.execute(
        select(LoyaltyTransaction)
        .where(LoyaltyTransaction.account_id == account.id)
        .order_by(LoyaltyTransaction.created_at.desc())
        .offset(skip).limit(limit)
    )
    return result.scalars().all()
