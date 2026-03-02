"""
Ground staff service: invite, accept, list, remove staff from grounds.
"""
import secrets
from datetime import datetime
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, and_

from src.apps.subscription.models.ground_staff import GroundStaff, StaffRole
from src.apps.futsal.models.ground import FutsalGround
from src.apps.iam.models.user import User


async def invite_staff(
    db: AsyncSession,
    ground_id: int,
    email: str,
    role: StaffRole,
    invited_by: int,
) -> GroundStaff:
    """Create a pending staff invite for the given ground."""
    # Check existing active record
    existing = await db.execute(
        select(GroundStaff).where(
            and_(GroundStaff.ground_id == ground_id, GroundStaff.invite_email == email)
        )
    )
    existing_staff = existing.scalars().first()
    if existing_staff and existing_staff.is_active and existing_staff.accepted_at:
        raise ValueError("This user is already a staff member for this ground.")

    token = secrets.token_urlsafe(32)
    staff = GroundStaff(
        ground_id=ground_id,
        user_id=0,  # will be resolved when invite is accepted by email lookup
        invited_by=invited_by,
        role=role,
        invite_token=token,
        invite_email=email,
    )
    db.add(staff)
    await db.flush()
    return staff


async def accept_invite(
    db: AsyncSession,
    token: str,
    user: User,
) -> GroundStaff:
    """User accepts an invite by token. Updates user_id and clears token."""
    result = await db.execute(
        select(GroundStaff).where(GroundStaff.invite_token == token)
    )
    staff = result.scalars().first()
    if not staff:
        raise ValueError("Invalid or expired invite token.")
    if staff.invite_email.lower() != user.email.lower():
        raise ValueError("This invite was sent to a different email address.")
    if staff.accepted_at:
        raise ValueError("This invite has already been accepted.")

    staff.user_id = user.id
    staff.accepted_at = datetime.utcnow()
    staff.invite_token = None  # one-time use
    staff.is_active = True
    db.add(staff)
    await db.commit()
    await db.refresh(staff)
    return staff


async def list_staff(db: AsyncSession, ground_id: int) -> list[GroundStaff]:
    result = await db.execute(
        select(GroundStaff).where(
            and_(GroundStaff.ground_id == ground_id, GroundStaff.is_active == True)
        )
    )
    return result.scalars().all()


async def remove_staff(db: AsyncSession, staff_id: int, owner_id: int) -> None:
    """Owner removes a staff member from the ground."""
    staff = await db.get(GroundStaff, staff_id)
    if not staff:
        raise ValueError("Staff record not found.")

    # Verify the owner owns the ground
    ground = await db.get(FutsalGround, staff.ground_id)
    if not ground or ground.owner_id != owner_id:
        raise PermissionError("You do not own this ground.")

    staff.is_active = False
    db.add(staff)
    await db.commit()


async def get_staff_role(
    db: AsyncSession, ground_id: int, user_id: int
) -> Optional[StaffRole]:
    """Returns the staff role for a user on a ground, or None."""
    result = await db.execute(
        select(GroundStaff.role).where(
            and_(
                GroundStaff.ground_id == ground_id,
                GroundStaff.user_id == user_id,
                GroundStaff.is_active == True,
                GroundStaff.accepted_at.is_not(None),
            )
        )
    )
    return result.scalars().first()
