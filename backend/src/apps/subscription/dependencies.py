"""
FastAPI dependencies for subscription + staff access control.
"""
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from src.apps.iam.api.deps import get_db, get_current_user as get_current_active_user
from src.apps.iam.models.user import User
from src.apps.subscription.services.subscription_service import (
    get_subscription,
    is_subscription_active,
)
from src.apps.subscription.services.staff_service import get_staff_role
from src.apps.subscription.models.ground_staff import StaffRole


async def require_active_subscription(
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Gate all owner-dashboard endpoints behind an active subscription.
    Superusers bypass this check (they are the platform operator).
    Raises 402 Payment Required if subscription is inactive/expired.
    """
    if getattr(current_user, "is_superuser", False):
        return current_user

    sub = await get_subscription(db, current_user.id)
    if not is_subscription_active(sub):
        raise HTTPException(
            status_code=status.HTTP_402_PAYMENT_REQUIRED,
            detail={
                "code": "subscription_required",
                "message": (
                    "Your subscription has expired or is not active. "
                    "Please subscribe or renew to access the owner dashboard."
                ),
                "subscription_status": sub.status.value if sub else "none",
            },
        )
    return current_user


async def require_ground_owner_or_manager(
    ground_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Passes if:
      - user is the ground owner (owner_id == current_user.id), OR
      - user is a MANAGER-role staff member for this ground, OR
      - user is superuser.
    Use on owner-dashboard routes that managers should also access.
    """
    from src.apps.futsal.models.ground import FutsalGround
    from sqlmodel import select

    if getattr(current_user, "is_superuser", False):
        return current_user

    ground = (
        await db.execute(select(FutsalGround).where(FutsalGround.id == ground_id))
    ).scalars().first()

    if not ground:
        raise HTTPException(status_code=404, detail="Ground not found.")

    if ground.owner_id == current_user.id:
        return current_user

    role = await get_staff_role(db, ground_id, current_user.id)
    if role == StaffRole.MANAGER:
        return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You must be the ground owner or an assigned manager to perform this action.",
    )


async def require_staff_checkin_access(
    ground_id: int,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    Passes for owners, MANAGER staff, and STAFF-role members.
    Used on check-in endpoint so even basic staff can scan QR codes.
    """
    from src.apps.futsal.models.ground import FutsalGround
    from sqlmodel import select

    if getattr(current_user, "is_superuser", False):
        return current_user

    ground = (
        await db.execute(select(FutsalGround).where(FutsalGround.id == ground_id))
    ).scalars().first()

    if not ground:
        raise HTTPException(status_code=404, detail="Ground not found.")

    if ground.owner_id == current_user.id:
        return current_user

    role = await get_staff_role(db, ground_id, current_user.id)
    if role in (StaffRole.MANAGER, StaffRole.STAFF):
        return current_user

    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="You must be a staff member of this ground to perform check-ins.",
    )
