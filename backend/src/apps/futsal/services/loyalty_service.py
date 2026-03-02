"""
Loyalty points service.
1 point per 100 NPR spent. Redeem 100 points = 10 NPR discount.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from src.apps.futsal.models.loyalty import LoyaltyAccount, LoyaltyTransaction, LoyaltyTransactionType

POINTS_PER_100_NPR = 1
POINTS_TO_NPR_RATE = 0.10  # 1 point = 0.10 NPR discount


async def get_or_create_account(db: AsyncSession, user_id: int) -> LoyaltyAccount:
    result = await db.execute(select(LoyaltyAccount).where(LoyaltyAccount.user_id == user_id))
    account = result.scalars().first()
    if not account:
        account = LoyaltyAccount(user_id=user_id)
        db.add(account)
        await db.flush()
    return account


async def earn_points(db: AsyncSession, user_id: int, booking_id: int, amount_npr: float) -> int:
    """Award points based on booking amount. Returns points earned."""
    points = int(amount_npr * POINTS_PER_100_NPR / 100)
    if points <= 0:
        return 0
    account = await get_or_create_account(db, user_id)
    account.points_balance += points
    account.total_earned += points
    from datetime import datetime
    account.updated_at = datetime.utcnow()
    db.add(account)

    tx = LoyaltyTransaction(
        account_id=account.id,
        booking_id=booking_id,
        transaction_type=LoyaltyTransactionType.EARNED,
        points=points,
        description=f"Earned for booking #{booking_id}",
    )
    db.add(tx)
    return points


async def redeem_points(
    db: AsyncSession, user_id: int, points_to_redeem: int
) -> float:
    """
    Deduct points and return NPR discount amount.
    Raises ValueError if insufficient balance.
    """
    account = await get_or_create_account(db, user_id)
    if account.points_balance < points_to_redeem:
        raise ValueError(f"Insufficient loyalty points. Balance: {account.points_balance}")

    discount = round(points_to_redeem * POINTS_TO_NPR_RATE, 2)
    account.points_balance -= points_to_redeem
    account.total_redeemed += points_to_redeem
    from datetime import datetime
    account.updated_at = datetime.utcnow()
    db.add(account)

    tx = LoyaltyTransaction(
        account_id=account.id,
        transaction_type=LoyaltyTransactionType.REDEEMED,
        points=-points_to_redeem,
        description=f"Redeemed {points_to_redeem} points for {discount} NPR discount",
    )
    db.add(tx)
    return discount
