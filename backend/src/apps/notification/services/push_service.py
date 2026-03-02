"""Web-push notification service (VAPID / RFC 8292)."""
import json
import logging
from typing import Any

from src.apps.core.config import settings

log = logging.getLogger(__name__)


def send_push_notification(
    endpoint: str,
    p256dh: str,
    auth: str,
    title: str,
    body: str,
    extra_data: Any = None,
) -> bool:
    """
    Send a Web Push notification to a single browser subscription.

    Returns True on success, False on failure.
    Requires PUSH_ENABLED=True and valid VAPID keys in settings.
    """
    if not settings.PUSH_ENABLED:
        log.debug("Push notifications disabled (PUSH_ENABLED=False)")
        return False

    if not settings.VAPID_PRIVATE_KEY or not settings.VAPID_PUBLIC_KEY:
        log.warning("VAPID keys not configured — skipping push notification")
        return False

    try:
        from pywebpush import webpush, WebPushException  # type: ignore

        payload = json.dumps(
            {
                "title": title,
                "body": body,
                "data": extra_data,
            }
        )

        webpush(
            subscription_info={
                "endpoint": endpoint,
                "keys": {"p256dh": p256dh, "auth": auth},
            },
            data=payload,
            vapid_private_key=settings.VAPID_PRIVATE_KEY,
            vapid_claims={"sub": settings.VAPID_CLAIMS_EMAIL},
        )
        log.info("Push notification sent to endpoint=%s", endpoint[:50])
        return True

    except Exception as exc:  # includes WebPushException
        log.warning("Push notification failed: %s", exc)
        return False
