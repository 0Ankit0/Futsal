from typing import Optional
from sqlmodel import Field, SQLModel


class CasbinRule(SQLModel, table=True):
    """
    Casbin policy rule storage model.
    This table stores all authorization policies and role mappings.
    Table name must match what casbin-async-sqlalchemy-adapter expects.
    """
    __tablename__ = "casbin_rule"  # type: ignore[assignment]

    id: Optional[int] = Field(
        default=None,
        primary_key=True
    )
    ptype: str = Field(
        max_length=255,
        index=True,
        description="Policy type (p for policy, g for grouping/role)"
    )
    v0: str = Field(
        default="",
        max_length=255,
        nullable=True,
        index=True,
        description="Subject (user/role)"
    )
    v1: str = Field(
        default="",
        max_length=255,
        nullable=True,
        index=True,
        description="Object (resource)"
    )
    v2: str = Field(
        default="",
        max_length=255,
        nullable=True,
        index=True,
        description="Action"
    )
    v3: str = Field(
        default="",
        max_length=255,
        nullable=True,
        description="Additional field"
    )
    v4: str = Field(
        default="",
        max_length=255,
        nullable=True,
        description="Additional field"
    )
    v5: str = Field(
        default="",
        max_length=255,
        nullable=True,
        description="Additional field"
    )
