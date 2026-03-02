from datetime import date, datetime
from typing import Optional, TYPE_CHECKING
from sqlmodel import Field, SQLModel, Relationship

if TYPE_CHECKING:
    from .ground import FutsalGround


class GroundClosureBase(SQLModel):
    ground_id: int = Field(foreign_key="futsal_grounds.id", index=True)
    start_date: date
    end_date: date
    reason: Optional[str] = Field(default=None, max_length=300)


class GroundClosure(GroundClosureBase, table=True):
    __tablename__ = "ground_closures"  # type: ignore

    id: Optional[int] = Field(default=None, primary_key=True)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    ground: Optional["FutsalGround"] = Relationship(back_populates="closures")
