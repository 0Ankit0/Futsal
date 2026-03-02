"""
Ground staff management API: invite, accept invite, list, remove.
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession

from src.apps.iam.api.deps import get_db, get_current_user as get_current_active_user
from src.apps.iam.models.user import User
from src.apps.subscription.models.ground_staff import GroundStaff, StaffRole
from src.apps.subscription.services.staff_service import (
    invite_staff,
    accept_invite,
    list_staff,
    remove_staff,
)
from src.apps.subscription.dependencies import require_active_subscription
from src.apps.futsal.models.ground import FutsalGround
from sqlmodel import select

router = APIRouter(prefix="/grounds/{ground_id}/staff", tags=["ground-staff"])


class StaffInviteRequest(BaseModel):
    email: EmailStr
    role: StaffRole = StaffRole.STAFF


class AcceptInviteRequest(BaseModel):
    token: str


class StaffResponse(BaseModel):
    id: int
    ground_id: int
    user_id: int
    invite_email: str
    role: StaffRole
    is_active: bool
    accepted_at: Optional[str]
    created_at: str


def _staff_to_response(s: GroundStaff) -> StaffResponse:
    return StaffResponse(
        id=s.id,
        ground_id=s.ground_id,
        user_id=s.user_id,
        invite_email=s.invite_email,
        role=s.role,
        is_active=s.is_active,
        accepted_at=s.accepted_at.isoformat() if s.accepted_at else None,
        created_at=s.created_at.isoformat(),
    )


async def _verify_ground_owner(db: AsyncSession, ground_id: int, owner_id: int) -> FutsalGround:
    result = await db.execute(
        select(FutsalGround).where(FutsalGround.id == ground_id)
    )
    ground = result.scalars().first()
    if not ground:
        raise HTTPException(status_code=404, detail="Ground not found.")
    if ground.owner_id != owner_id:
        raise HTTPException(status_code=403, detail="You do not own this ground.")
    return ground


@router.get("", response_model=list[StaffResponse])
async def get_staff_list(
    ground_id: int,
    current_user: User = Depends(require_active_subscription),
    db: AsyncSession = Depends(get_db),
):
    """Owner: list all active staff for a ground."""
    await _verify_ground_owner(db, ground_id, current_user.id)
    staff = await list_staff(db, ground_id)
    return [_staff_to_response(s) for s in staff]


@router.post("/invite", response_model=StaffResponse, status_code=201)
async def invite_staff_member(
    ground_id: int,
    req: StaffInviteRequest,
    current_user: User = Depends(require_active_subscription),
    db: AsyncSession = Depends(get_db),
):
    """
    Owner: invite a staff member by email.
    An invite token is generated; the frontend sends an invite email with a link.
    The invited user must call /accept-invite with the token to join.
    """
    # Verify subscription plan allows more staff
    from sqlmodel import select as sel
    from src.apps.subscription.models.subscription import OwnerSubscription
    from src.apps.subscription.models.plan import SubscriptionPlan

    sub_result = await db.execute(
        sel(OwnerSubscription).where(OwnerSubscription.owner_id == current_user.id)
    )
    sub = sub_result.scalars().first()
    if sub:
        plan = await db.get(SubscriptionPlan, sub.plan_id)
        if plan:
            existing_staff = await list_staff(db, ground_id)
            if len(existing_staff) >= plan.max_staff:
                raise HTTPException(
                    status_code=403,
                    detail=f"Your plan allows a maximum of {plan.max_staff} staff members. Upgrade to add more.",
                )

    await _verify_ground_owner(db, ground_id, current_user.id)
    try:
        staff = await invite_staff(db, ground_id, req.email, req.role, current_user.id)
    except ValueError as e:
        raise HTTPException(status_code=409, detail=str(e))

    # TODO: send invite email via notification module
    # await send_staff_invite_email(email=req.email, token=staff.invite_token, ground=ground)

    await db.commit()
    await db.refresh(staff)
    return _staff_to_response(staff)


@router.delete("/{staff_id}", status_code=204)
async def remove_staff_member(
    ground_id: int,
    staff_id: int,
    current_user: User = Depends(require_active_subscription),
    db: AsyncSession = Depends(get_db),
):
    """Owner: remove a staff member from the ground."""
    try:
        await remove_staff(db, staff_id, current_user.id)
    except (ValueError, PermissionError) as e:
        raise HTTPException(status_code=400, detail=str(e))


# Accept invite endpoint (no auth needed at route level — token IS the auth)
accept_router = APIRouter(prefix="/staff", tags=["ground-staff"])


@accept_router.post("/accept-invite", status_code=200)
async def accept_staff_invite(
    req: AcceptInviteRequest,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
):
    """Any authenticated user: accept a staff invite by token."""
    try:
        staff = await accept_invite(db, req.token, current_user)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"message": "You have joined the ground team.", "role": staff.role}
