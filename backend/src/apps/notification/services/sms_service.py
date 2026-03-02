"""SMS notification service via Twilio."""
import logging

from src.apps.core.config import settings

log = logging.getLogger(__name__)


def send_sms_notification(
    to_number: str,
    body: str,
) -> bool:
    """
    Send an SMS to *to_number* using Twilio.

    Returns True on success, False on failure.
    Requires SMS_ENABLED=True and valid Twilio credentials in settings.
    """
    if not settings.SMS_ENABLED:
        log.debug("SMS notifications disabled (SMS_ENABLED=False)")
        return False

    if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_AUTH_TOKEN:
        log.warning("Twilio credentials not configured — skipping SMS notification")
        return False

    if not to_number:
        log.debug("No phone number for user — skipping SMS notification")
        return False

    try:
        from twilio.rest import Client  # type: ignore

        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        message = client.messages.create(
            body=body,
            from_=settings.TWILIO_FROM_NUMBER,
            to=to_number,
        )
        log.info("SMS sent: sid=%s to=%s", message.sid, to_number)
        return True

    except Exception as exc:
        log.warning("SMS notification failed for %s: %s", to_number, exc)
        return False
