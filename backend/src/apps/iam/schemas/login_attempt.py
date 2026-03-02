from datetime import datetime
from pydantic import BaseModel, field_serializer
from ..utils.hashid import encode_id


class LoginAttemptResponse(BaseModel):
    id: int
    user_id: int
    ip_address: str
    user_agent: str
    success: bool
    failure_reason: str
    timestamp: datetime

    @field_serializer("id", "user_id")
    def serialize_ids(self, value: int) -> str:
        return encode_id(value)
