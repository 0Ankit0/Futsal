"""Notification service — persist + multi-channel delivery (WebSocket, email, push, SMS)."""
import logging
from typing import Optional

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import col

from src.apps.notification.models.notification import Notification
from src.apps.notification.models.notification_preference import NotificationPreference
from src.apps.notification.schemas.notification import (
    NotificationCreate,
    NotificationList,
    NotificationRead,
)
from src.apps.notification.tasks import (
    send_notification_email_task,
    send_push_notification_task,
    send_sms_notification_task,
)

log = logging.getLogger(__name__)


async def _get_or_create_preference(
    db: AsyncSession, user_id: int
) -> NotificationPreference:
    """Return the user's NotificationPreference, creating a default row if absent."""
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


async def create_notification(
    db: AsyncSession,
    data: NotificationCreate,
    push_ws: bool = True,
) -> Notification:
    """
    Persist a notification then dispatch it over every channel the user has
    enabled in their NotificationPreference.

    Channel behaviour:
    - websocket — real-time; best-effort (silently skipped if offline)
    - email     — queued via Celery; requires user email address
    - push      — Web Push via pywebpush; requires stored push subscription
    - sms       — Twilio SMS; requires user phone number
    """
    notification = Notification(
        user_id=data.user_id,
        title=data.title,
        body=data.body,
        type=data.type,
        extra_data=data.extra_data,
    )
    db.add(notification)
    await db.commit()
    await db.refresh(notification)

    pref = await _get_or_create_preference(db, data.user_id)

    if push_ws and pref.websocket_enabled:
        await _push_to_ws(notification)

    if pref.email_enabled:
        await _push_to_email(db, notification)

    if pref.push_enabled:
        await _push_to_web_push(pref, notification)

    if pref.sms_enabled:
        await _push_to_sms(db, notification)

    return notification


async def _push_to_ws(notification: Notification) -> None:
    """Push notification to the user's active WebSocket connections (if any)."""
    try:
        from src.apps.websocket.manager import manager

        await manager.push_event(
            user_id=notification.user_id,
            event="notification.new",
            data={
                "id": notification.id,
                "title": notification.title,
                "body": notification.body,
                "type": notification.type,
                "is_read": notification.is_read,
                "extra_data": notification.extra_data,
                "created_at": notification.created_at.isoformat(),
            },
        )
    except Exception as exc:
        log.warning("WS push failed for notification id=%s: %s", notification.id, exc)


async def _push_to_email(db: AsyncSession, notification: Notification) -> None:
    """Queue an email copy of the notification via Celery."""
    try:
        from src.apps.iam.models.user import User

        result = await db.execute(
            select(User).where(col(User.id) == notification.user_id)
        )
        user = result.scalars().first()
        if not user:
            return

        send_notification_email_task.delay(
            recipients=[{"name": user.username, "email": user.email}],
            subject=notification.title,
            context={
                "user": {"email": user.email, "first_name": user.username},
                "notification": {
                    "title": notification.title,
                    "body": notification.body,
                    "type": notification.type,
                },
            },
        )
    except Exception as exc:
        log.warning("Email push failed for notification id=%s: %s", notification.id, exc)


async def _push_to_web_push(
    pref: NotificationPreference, notification: Notification
) -> None:
    """Dispatch a Web Push notification via Celery if a subscription is stored."""
    if not (pref.push_endpoint and pref.push_p256dh and pref.push_auth):
        log.debug(
            "No push subscription stored for user_id=%s — skipping push",
            notification.user_id,
        )
        return
    try:
        send_push_notification_task.delay(
            endpoint=pref.push_endpoint,
            p256dh=pref.push_p256dh,
            auth=pref.push_auth,
            title=notification.title,
            body=notification.body,
            extra_data=notification.extra_data if isinstance(notification.extra_data, dict) else None,
        )
    except Exception as exc:
        log.warning("Push task enqueue failed for notification id=%s: %s", notification.id, exc)


async def _push_to_sms(db: AsyncSession, notification: Notification) -> None:
    """Dispatch an SMS via Celery using the user's profile phone number."""
    try:
        from src.apps.iam.models.user import UserProfile

        result = await db.execute(
            select(UserProfile).where(col(UserProfile.user_id) == notification.user_id)
        )
        profile = result.scalars().first()
        if not profile or not profile.phone:
            log.debug(
                "No phone number for user_id=%s — skipping SMS", notification.user_id
            )
            return

        send_sms_notification_task.delay(
            to_number=profile.phone,
            body=f"{notification.title}: {notification.body}",
        )
    except Exception as exc:
        log.warning("SMS task enqueue failed for notification id=%s: %s", notification.id, exc)


async def get_user_notifications(
    db: AsyncSession,
    user_id: int,
    *,
    unread_only: bool = False,
    skip: int = 0,
    limit: int = 20,
) -> NotificationList:
    """Return paginated notifications for a user."""
    base_query = select(Notification).where(col(Notification.user_id) == user_id)
    if unread_only:
        base_query = base_query.where(col(Notification.is_read) == False)  # noqa: E712

    count_result = await db.execute(
        select(func.count()).select_from(base_query.subquery())
    )
    total = count_result.scalar_one()

    unread_result = await db.execute(
        select(func.count()).select_from(
            select(Notification)
            .where(and_(col(Notification.user_id) == user_id, col(Notification.is_read) == False))  # noqa: E712
            .subquery()
        )
    )
    unread_count = unread_result.scalar_one()

    result = await db.execute(
        base_query.order_by(col(Notification.created_at).desc()).offset(skip).limit(limit)
    )
    items = result.scalars().all()

    return NotificationList(
        items=[NotificationRead.model_validate(n) for n in items],
        total=total,
        unread_count=unread_count,
    )


async def get_notification(
    db: AsyncSession,
    notification_id: int,
    user_id: int,
) -> Optional[Notification]:
    """Fetch a single notification belonging to the given user."""
    result = await db.execute(
        select(Notification).where(
            and_(col(Notification.id) == notification_id, col(Notification.user_id) == user_id)
        )
    )
    return result.scalars().first()


async def mark_as_read(
    db: AsyncSession,
    notification_id: int,
    user_id: int,
) -> Optional[Notification]:
    """Mark a single notification as read. Returns None if not found."""
    notification = await get_notification(db, notification_id, user_id)
    if not notification:
        return None
    notification.is_read = True
    db.add(notification)
    await db.commit()
    await db.refresh(notification)
    return notification


async def mark_all_read(db: AsyncSession, user_id: int) -> int:
    """Mark all unread notifications for a user as read. Returns the count updated."""
    result = await db.execute(
        select(Notification).where(
            and_(col(Notification.user_id) == user_id, col(Notification.is_read) == False)  # noqa: E712
        )
    )
    notifications = result.scalars().all()
    for n in notifications:
        n.is_read = True
        db.add(n)
    await db.commit()
    return len(notifications)


async def delete_notification(
    db: AsyncSession,
    notification_id: int,
    user_id: int,
) -> bool:
    """Delete a notification. Returns True if deleted, False if not found."""
    notification = await get_notification(db, notification_id, user_id)
    if not notification:
        return False
    await db.delete(notification)
    await db.commit()
    return True
