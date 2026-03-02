"""Notification-specific Celery tasks (email copy, Web Push, SMS)."""
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

from celery import shared_task

from src.apps.core.celery_app import celery_app  # noqa: F401 — bind tasks to configured app

logger = logging.getLogger(__name__)

# Templates live in this module — resolved once at import time so Celery
# workers (which run in a separate process) get the correct absolute path.
NOTIFICATION_TEMPLATE_DIR = str(Path(__file__).resolve().parent.parent / "templates")


@shared_task(name="send_notification_email_task")
def send_notification_email_task(
    recipients: List[Dict[str, str]],
    subject: str,
    context: Dict[str, Any],
) -> bool:
    """Send an email copy of a notification using the notification module template."""
    from src.apps.core.tasks import send_email_task

    return send_email_task(
        subject=subject,
        recipients=recipients,
        template_name="notification",
        context=context,
        template_dir=NOTIFICATION_TEMPLATE_DIR,
    )


@shared_task(name="send_push_notification_task")
def send_push_notification_task(
    endpoint: str,
    p256dh: str,
    auth: str,
    title: str,
    body: str,
    extra_data: Optional[Dict[str, Any]] = None,
) -> bool:
    """Send a Web Push notification to a browser subscription."""
    from src.apps.notification.services.push_service import send_push_notification

    return send_push_notification(endpoint, p256dh, auth, title, body, extra_data)


@shared_task(name="send_sms_notification_task")
def send_sms_notification_task(to_number: str, body: str) -> bool:
    """Send an SMS notification via Twilio."""
    from src.apps.notification.services.sms_service import send_sms_notification

    return send_sms_notification(to_number, body)
