from datetime import datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User


class GatewayProvider(str, Enum):
    KHALTI = "khalti"
    ESEWA = "esewa"
    BANK_TRANSFER = "bank_transfer"


class OwnerPaymentGateway(SQLModel, table=True):
    """
    Stores ground owner's payment gateway credentials (AES-256 encrypted).
    Superuser must verify before first payout is processed.
    """
    __tablename__ = "owner_payment_gateways"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    owner_id: int = Field(foreign_key="user.id", unique=True, index=True)
    provider: GatewayProvider
    credentials_encrypted: str = Field(
        description="AES-256 encrypted JSON blob of gateway credentials"
    )
    account_name: str = Field(max_length=150)
    account_number_hint: str = Field(
        max_length=10,
        description="Last 4 digits / masked identifier shown to owner"
    )
    is_active: bool = Field(default=True)
    is_verified: bool = Field(
        default=False,
        description="Superuser must verify credentials before first payout"
    )
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    owner: Optional["User"] = Relationship()
