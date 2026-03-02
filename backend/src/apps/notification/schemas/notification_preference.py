"""Pydantic schemas for NotificationPreference."""
from typing import Optional

from pydantic import BaseModel, HttpUrl


class NotificationPreferenceRead(BaseModel):
    id: int
    user_id: int
    websocket_enabled: bool
    email_enabled: bool
    push_enabled: bool
    sms_enabled: bool
    push_endpoint: Optional[str] = None

    model_config = {"from_attributes": True}


class NotificationPreferenceUpdate(BaseModel):
    """Update channel-level flags. Only provided fields are changed."""

    websocket_enabled: Optional[bool] = None
    email_enabled: Optional[bool] = None
    push_enabled: Optional[bool] = None
    sms_enabled: Optional[bool] = None


class PushSubscriptionUpdate(BaseModel):
    """
    Payload sent by the browser after the user grants push permission.
    Maps to the standard PushSubscription JSON object.
    """

    endpoint: str
    p256dh: str
    auth: str
