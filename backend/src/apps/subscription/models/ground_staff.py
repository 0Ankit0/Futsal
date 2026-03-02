"""
Ground staff model — links a tenant member to a specific ground with a role.
Owners can invite managers who manage bookings/analytics on their behalf.
"""
from datetime import datetime
from enum import Enum
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, UniqueConstraint, Relationship

if TYPE_CHECKING:
    from src.apps.iam.models.user import User
    from src.apps.futsal.models.ground import FutsalGround


class StaffRole(str, Enum):
    MANAGER = "manager"  # Full access: bookings, analytics, ground edit, checkin
    STAFF   = "staff"    # Limited: view bookings, perform QR checkin only


class GroundStaff(SQLModel, table=True):
    """Maps an invited user to a ground with a specific staff role."""
    __tablename__ = "ground_staff"  # type: ignore
    __table_args__ = (
        UniqueConstraint("ground_id", "user_id", name="uq_ground_staff"),
    )

    id: Optional[int] = Field(default=None, primary_key=True)
    ground_id: int = Field(foreign_key="futsal_grounds.id", index=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    invited_by: int = Field(foreign_key="user.id", description="Owner who added this staff member")
    role: StaffRole = Field(default=StaffRole.STAFF)
    is_active: bool = Field(default=True)
    invite_token: Optional[str] = Field(
        default=None, unique=True, index=True, max_length=64,
        description="One-time token sent by email; cleared after acceptance"
    )
    invite_email: str = Field(max_length=255, description="Email the invite was sent to")
    accepted_at: Optional[datetime] = Field(default=None)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    ground: Optional["FutsalGround"] = Relationship()
    user: Optional["User"] = Relationship(
        sa_relationship_kwargs={"foreign_keys": "[GroundStaff.user_id]"}
    )
    inviter: Optional["User"] = Relationship(
        sa_relationship_kwargs={"foreign_keys": "[GroundStaff.invited_by]"}
    )
