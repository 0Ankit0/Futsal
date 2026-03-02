"""Payout gateway configuration API."""
from datetime import datetime
from typing import Annotated, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select, SQLModel

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.payout.models.owner_gateway import OwnerPaymentGateway, GatewayProvider
from src.apps.payout.services.encryption import encrypt_credentials

router = APIRouter(prefix="/payout/gateway", tags=["Payout Gateway"])


class GatewayConfigCreate(SQLModel):
    provider: GatewayProvider
    account_name: str
    credentials: dict  # raw credentials dict — will be encrypted before storage


class GatewayConfigResponse(SQLModel):
    id: int
    provider: GatewayProvider
    account_name: str
    account_number_hint: str
    is_active: bool
    is_verified: bool
    created_at: datetime


def _mask_hint(creds: dict, provider: GatewayProvider) -> str:
    """Extract a masked identifier for display (last 4 digits)."""
    for key in ("mobile", "account_number", "merchant_code"):
        val = creds.get(key, "")
        if val:
            return "****" + str(val)[-4:]
    return "****"


@router.get("", response_model=Optional[GatewayConfigResponse])
async def get_my_gateway(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    result = await db.execute(
        select(OwnerPaymentGateway).where(OwnerPaymentGateway.owner_id == current_user.id)
    )
    return result.scalars().first()


@router.post("", response_model=GatewayConfigResponse, status_code=status.HTTP_201_CREATED)
async def configure_gateway(
    data: GatewayConfigCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Owner sets up their payment gateway credentials (stored encrypted)."""
    # Check for existing config
    existing = await db.execute(
        select(OwnerPaymentGateway).where(OwnerPaymentGateway.owner_id == current_user.id)
    )
    if existing.scalars().first():
        raise HTTPException(status_code=409, detail="Gateway already configured. Use PUT to update.")

    gateway = OwnerPaymentGateway(
        owner_id=current_user.id,
        provider=data.provider,
        credentials_encrypted=encrypt_credentials(data.credentials),
        account_name=data.account_name,
        account_number_hint=_mask_hint(data.credentials, data.provider),
        is_active=True,
        is_verified=False,  # Must be verified by superuser before first payout
    )
    db.add(gateway)
    await db.commit()
    await db.refresh(gateway)
    return gateway


@router.put("", response_model=GatewayConfigResponse)
async def update_gateway(
    data: GatewayConfigCreate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    result = await db.execute(
        select(OwnerPaymentGateway).where(OwnerPaymentGateway.owner_id == current_user.id)
    )
    gateway = result.scalars().first()
    if not gateway:
        raise HTTPException(status_code=404, detail="No gateway configured.")
    gateway.provider = data.provider
    gateway.credentials_encrypted = encrypt_credentials(data.credentials)
    gateway.account_name = data.account_name
    gateway.account_number_hint = _mask_hint(data.credentials, data.provider)
    gateway.is_verified = False  # Re-verify required after credentials change
    gateway.updated_at = datetime.utcnow()
    db.add(gateway)
    await db.commit()
    await db.refresh(gateway)
    return gateway


@router.post("/verify/{owner_id}", response_model=GatewayConfigResponse)
async def verify_owner_gateway(
    owner_id: int,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Superuser only: mark owner's gateway as verified."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Superuser only.")
    result = await db.execute(
        select(OwnerPaymentGateway).where(OwnerPaymentGateway.owner_id == owner_id)
    )
    gateway = result.scalars().first()
    if not gateway:
        raise HTTPException(status_code=404, detail="Gateway not found.")
    gateway.is_verified = True
    gateway.updated_at = datetime.utcnow()
    db.add(gateway)
    await db.commit()
    await db.refresh(gateway)
    return gateway
