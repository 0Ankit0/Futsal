"""
Tenant (multitenancy) API endpoints — CRUD, member management, invitations.
"""
import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, func, col

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.casbin_enforcer import CasbinEnforcer
from src.apps.multitenancy.models.tenant import (
    InvitationStatus,
    Tenant,
    TenantInvitation,
    TenantMember,
    TenantRole,
)
from src.apps.iam.models.user import User
from src.apps.multitenancy.schemas.tenant import (
    AcceptInvitationRequest,
    TenantCreate,
    TenantInvitationCreate,
    TenantInvitationResponse,
    TenantMemberResponse,
    TenantMemberUpdate,
    TenantResponse,
    TenantUpdate,
    TenantWithMembersResponse,
)
from src.apps.iam.utils.hashid import decode_id_or_404
from src.apps.core.cache import RedisCache
from src.apps.core.schemas import PaginatedResponse

router = APIRouter()

_INVITATION_TTL_HOURS = 48


# ── helpers ───────────────────────────────────────────────────────────────────

async def _get_tenant_or_404(tenant_id: int, db: AsyncSession) -> Tenant:
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tenant not found")
    return tenant


async def _require_tenant_role(
    tenant_id: int,
    user: User,
    db: AsyncSession,
    min_role: TenantRole = TenantRole.ADMIN,
) -> TenantMember:
    """Raise 403 if user does not have at least `min_role` in this tenant."""
    membership = (
        await db.execute(
            select(TenantMember).where(
                TenantMember.tenant_id == tenant_id,
                TenantMember.user_id == user.id,
                TenantMember.is_active == True,
            )
        )
    ).scalars().first()

    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member of this tenant")

    role_order = {TenantRole.MEMBER: 0, TenantRole.ADMIN: 1, TenantRole.OWNER: 2}
    if role_order[membership.role] < role_order[min_role]:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions in tenant")

    return membership


# ── Tenant CRUD ───────────────────────────────────────────────────────────────

@router.post("/", response_model=TenantResponse, status_code=status.HTTP_201_CREATED)
async def create_tenant(
    data: TenantCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new tenant. The calling user becomes the owner."""
    existing = (
        await db.execute(select(Tenant).where(Tenant.slug == data.slug))
    ).scalars().first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Slug already taken")

    tenant = Tenant(
        name=data.name,
        slug=data.slug,
        description=data.description,
        owner_id=current_user.id,
    )
    db.add(tenant)
    await db.flush()  # get tenant.id before commit

    # Auto-add owner as a member
    membership = TenantMember(
        tenant_id=tenant.id,
        user_id=current_user.id,
        role=TenantRole.OWNER,
    )
    db.add(membership)
    await db.commit()
    await db.refresh(tenant)

    # Add Casbin grouping: owner gets "owner" role in tenant domain
    await CasbinEnforcer.add_role_for_user(str(current_user.id), TenantRole.OWNER, tenant.slug)

    await RedisCache.clear_pattern(f"tenants:list:*")
    return tenant


@router.get("/", response_model=PaginatedResponse[TenantResponse])
async def list_my_tenants(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=10, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all tenants the current user is a member of."""
    cache_key = f"tenants:list:{current_user.id}:{skip}:{limit}"
    cached = await RedisCache.get(cache_key)
    if cached:
        return cached

    total = (
        await db.execute(
            select(func.count(col(Tenant.id)))
            .join(TenantMember, TenantMember.tenant_id == Tenant.id)
            .where(TenantMember.user_id == current_user.id, TenantMember.is_active == True)
        )
    ).scalar_one()

    items = (
        await db.execute(
            select(Tenant)
            .join(TenantMember, TenantMember.tenant_id == Tenant.id)
            .where(TenantMember.user_id == current_user.id, TenantMember.is_active == True)
            .offset(skip)
            .limit(limit)
        )
    ).scalars().all()

    items_resp = [TenantResponse.model_validate(t) for t in items]
    response = PaginatedResponse[TenantResponse].create(items=items_resp, total=total, skip=skip, limit=limit)
    await RedisCache.set(cache_key, response.model_dump(), ttl=120)
    return response


@router.get("/{tenant_id}", response_model=TenantWithMembersResponse)
async def get_tenant(
    tenant_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get tenant details (must be a member)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.MEMBER)
    tenant = await _get_tenant_or_404(tenant_id, db)

    members_raw = (
        await db.execute(
            select(TenantMember).where(TenantMember.tenant_id == tenant_id)
        )
    ).scalars().all()

    response = TenantWithMembersResponse(
        **TenantResponse.model_validate(tenant).model_dump(),
        members=[TenantMemberResponse.model_validate(m) for m in members_raw],
    )
    return response


@router.patch("/{tenant_id}", response_model=TenantResponse)
async def update_tenant(
    tenant_id: int,
    data: TenantUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update tenant details (admin or owner only)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)
    tenant = await _get_tenant_or_404(tenant_id, db)

    update_fields = data.model_dump(exclude_unset=True)
    for field, value in update_fields.items():
        setattr(tenant, field, value)
    tenant.updated_at = datetime.now()

    await db.commit()
    await db.refresh(tenant)

    await RedisCache.clear_pattern(f"tenants:list:*")
    return tenant


@router.delete("/{tenant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_tenant(
    tenant_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a tenant (owner only)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.OWNER)
    tenant = await _get_tenant_or_404(tenant_id, db)
    await db.delete(tenant)
    await db.commit()
    await RedisCache.clear_pattern(f"tenants:list:*")


# ── Member management ─────────────────────────────────────────────────────────

@router.get("/{tenant_id}/members", response_model=PaginatedResponse[TenantMemberResponse])
async def list_members(
    tenant_id: int,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all members of a tenant."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.MEMBER)

    total = (
        await db.execute(
            select(func.count(col(TenantMember.id))).where(TenantMember.tenant_id == tenant_id)
        )
    ).scalar_one()

    items = (
        await db.execute(
            select(TenantMember)
            .where(TenantMember.tenant_id == tenant_id)
            .offset(skip)
            .limit(limit)
        )
    ).scalars().all()

    items_resp = [TenantMemberResponse.model_validate(m) for m in items]
    return PaginatedResponse[TenantMemberResponse].create(items=items_resp, total=total, skip=skip, limit=limit)


@router.patch("/{tenant_id}/members/{user_id}", response_model=TenantMemberResponse)
async def update_member_role(
    tenant_id: int,
    user_id: int,
    data: TenantMemberUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update a member's role (admin/owner only; only owner can promote to owner)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)

    if data.role == TenantRole.OWNER:
        # Only current owner can hand off ownership
        await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.OWNER)

    membership = (
        await db.execute(
            select(TenantMember).where(
                TenantMember.tenant_id == tenant_id,
                TenantMember.user_id == user_id,
            )
        )
    ).scalars().first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")

    tenant = await _get_tenant_or_404(tenant_id, db)

    # Update Casbin: remove old role, add new
    await CasbinEnforcer.remove_role_for_user(str(user_id), membership.role, tenant.slug)
    membership.role = data.role
    await CasbinEnforcer.add_role_for_user(str(user_id), data.role, tenant.slug)

    await db.commit()
    await db.refresh(membership)
    return membership


@router.delete("/{tenant_id}/members/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_member(
    tenant_id: int,
    user_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove a member from the tenant (admin/owner, or user removing themselves)."""
    if user_id != current_user.id:
        await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)

    membership = (
        await db.execute(
            select(TenantMember).where(
                TenantMember.tenant_id == tenant_id,
                TenantMember.user_id == user_id,
            )
        )
    ).scalars().first()
    if not membership:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")

    tenant = await _get_tenant_or_404(tenant_id, db)

    # Prevent removing the last owner
    if membership.role == TenantRole.OWNER:
        owners_count = (
            await db.execute(
                select(func.count(col(TenantMember.id))).where(
                    TenantMember.tenant_id == tenant_id,
                    TenantMember.role == TenantRole.OWNER,
                )
            )
        ).scalar_one()
        if owners_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot remove the last owner. Transfer ownership first.",
            )

    await CasbinEnforcer.remove_role_for_user(str(user_id), membership.role, tenant.slug)
    await db.delete(membership)
    await db.commit()


# ── Invitations ───────────────────────────────────────────────────────────────

@router.post("/{tenant_id}/invitations", response_model=TenantInvitationResponse, status_code=status.HTTP_201_CREATED)
async def invite_member(
    tenant_id: int,
    data: TenantInvitationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Invite a user to a tenant by email (admin/owner only)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)
    await _get_tenant_or_404(tenant_id, db)

    # Check for active pending invitation for this email
    existing = (
        await db.execute(
            select(TenantInvitation).where(
                TenantInvitation.tenant_id == tenant_id,
                TenantInvitation.email == data.email,
                TenantInvitation.status == InvitationStatus.PENDING,
            )
        )
    ).scalars().first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An active invitation already exists for this email",
        )

    invitation = TenantInvitation(
        tenant_id=tenant_id,
        email=str(data.email),
        role=data.role,
        invited_by=current_user.id,
        token=str(uuid.uuid4()),
        expires_at=datetime.now() + timedelta(hours=_INVITATION_TTL_HOURS),
    )
    db.add(invitation)
    await db.commit()
    await db.refresh(invitation)
    return invitation


@router.get("/{tenant_id}/invitations", response_model=PaginatedResponse[TenantInvitationResponse])
async def list_invitations(
    tenant_id: int,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List invitations for a tenant (admin/owner only)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)

    total = (
        await db.execute(
            select(func.count(col(TenantInvitation.id))).where(
                TenantInvitation.tenant_id == tenant_id
            )
        )
    ).scalar_one()

    items = (
        await db.execute(
            select(TenantInvitation)
            .where(TenantInvitation.tenant_id == tenant_id)
            .offset(skip)
            .limit(limit)
        )
    ).scalars().all()

    items_resp = [TenantInvitationResponse.model_validate(i) for i in items]
    return PaginatedResponse[TenantInvitationResponse].create(items=items_resp, total=total, skip=skip, limit=limit)


@router.post("/invitations/accept", response_model=TenantMemberResponse)
async def accept_invitation(
    body: AcceptInvitationRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Accept an invitation token and join the tenant."""
    invitation = (
        await db.execute(
            select(TenantInvitation).where(TenantInvitation.token == body.token)
        )
    ).scalars().first()

    if not invitation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")

    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invitation is {invitation.status}",
        )

    if invitation.expires_at < datetime.now():
        invitation.status = InvitationStatus.EXPIRED
        await db.commit()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invitation has expired")

    if invitation.email != current_user.email:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This invitation was sent to a different email address",
        )

    # Check already a member
    already = (
        await db.execute(
            select(TenantMember).where(
                TenantMember.tenant_id == invitation.tenant_id,
                TenantMember.user_id == current_user.id,
            )
        )
    ).scalars().first()
    if already:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Already a member of this tenant")

    tenant = await _get_tenant_or_404(invitation.tenant_id, db)

    membership = TenantMember(
        tenant_id=invitation.tenant_id,
        user_id=current_user.id,
        role=invitation.role,
    )
    db.add(membership)

    invitation.status = InvitationStatus.ACCEPTED
    invitation.accepted_at = datetime.now()
    await db.commit()
    await db.refresh(membership)

    # Add Casbin role in tenant domain
    await CasbinEnforcer.add_role_for_user(str(current_user.id), invitation.role, tenant.slug)
    await RedisCache.clear_pattern(f"tenants:list:*")
    return membership


@router.delete("/{tenant_id}/invitations/{invitation_id}", status_code=status.HTTP_204_NO_CONTENT)
async def revoke_invitation(
    tenant_id: int,
    invitation_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Revoke a pending invitation (admin/owner only)."""
    await _require_tenant_role(tenant_id, current_user, db, min_role=TenantRole.ADMIN)

    invitation = (
        await db.execute(
            select(TenantInvitation).where(
                TenantInvitation.id == invitation_id,
                TenantInvitation.tenant_id == tenant_id,
            )
        )
    ).scalars().first()
    if not invitation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found")

    if invitation.status != InvitationStatus.PENDING:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only pending invitations can be revoked",
        )

    invitation.status = InvitationStatus.REVOKED
    await db.commit()
