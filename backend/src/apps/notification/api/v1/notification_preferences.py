"""
Notification preference REST API.

Endpoints
─────────
  GET    /notifications/preferences/              — get current user's preferences
  PATCH  /notifications/preferences/              — update channel flags
  PUT    /notifications/preferences/push-subscription/ — store browser push subscription
  DELETE /notifications/preferences/push-subscription/ — remove push subscription
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col

from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.notification.models.notification_preference import NotificationPreference
from src.apps.notification.schemas.notification_preference import (
    NotificationPreferenceRead,
    NotificationPreferenceUpdate,
    PushSubscriptionUpdate,
)

router = APIRouter()


async def _get_or_create_pref(db: AsyncSession, user_id: int) -> NotificationPreference:
    result = await db.execute(
        select(NotificationPreference).where(col(NotificationPreference.user_id) == user_id)
    )
    pref = result.scalars().first()
    if pref is None:
        pref = NotificationPreference(user_id=user_id)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)
    return pref


@router.get(
    "/preferences/",
    response_model=NotificationPreferenceRead,
    summary="Get notification channel preferences",
)
async def get_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationPreferenceRead:
    """Return the current user's notification channel subscription flags."""

    assert isinstance(current_user.id, int),"User Id can't be None"
    pref = await _get_or_create_pref(db, current_user.id)
    return NotificationPreferenceRead.model_validate(pref)


@router.patch(
    "/preferences/",
    response_model=NotificationPreferenceRead,
    summary="Update notification channel preferences",
)
async def update_preferences(
    data: NotificationPreferenceUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationPreferenceRead:
    """
    Toggle individual notification channels on or off.
    Only fields that are explicitly provided will be updated.
    """

    assert isinstance(current_user.id, int),"User Id can't be None"
    pref = await _get_or_create_pref(db, current_user.id)

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(pref, field, value)

    db.add(pref)
    await db.commit()
    await db.refresh(pref)
    return NotificationPreferenceRead.model_validate(pref)


@router.put(
    "/preferences/push-subscription/",
    response_model=NotificationPreferenceRead,
    summary="Register browser push subscription",
)
async def register_push_subscription(
    data: PushSubscriptionUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> NotificationPreferenceRead:
    """
    Store the browser's PushSubscription object so the server can send Web Push
    notifications.  Also automatically enables the push channel.
    """

    assert isinstance(current_user.id, int),"User Id can't be None"
    pref = await _get_or_create_pref(db, current_user.id)
    pref.push_endpoint = data.endpoint
    pref.push_p256dh = data.p256dh
    pref.push_auth = data.auth
    pref.push_enabled = True
    db.add(pref)
    await db.commit()
    await db.refresh(pref)
    return NotificationPreferenceRead.model_validate(pref)


@router.delete(
    "/preferences/push-subscription/",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Remove browser push subscription",
)
async def remove_push_subscription(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """
    Remove the stored push subscription and disable the push channel.
    """

    assert isinstance(current_user.id, int),"User Id can't be None"
    pref = await _get_or_create_pref(db, current_user.id)
    pref.push_endpoint = None
    pref.push_p256dh = None
    pref.push_auth = None
    pref.push_enabled = False
    db.add(pref)
    await db.commit()
