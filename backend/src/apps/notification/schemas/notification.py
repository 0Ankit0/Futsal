"""Notification Pydantic schemas."""
from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel

from src.apps.notification.models.notification import NotificationType


class NotificationCreate(BaseModel):
    user_id: int
    title: str
    body: str
    type: NotificationType = NotificationType.INFO
    extra_data: Optional[Any] = None


class NotificationRead(BaseModel):
    id: int
    user_id: int
    title: str
    body: str
    type: NotificationType
    is_read: bool
    extra_data: Optional[Any]
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None


class NotificationList(BaseModel):
    items: list[NotificationRead]
    total: int
    unread_count: int
