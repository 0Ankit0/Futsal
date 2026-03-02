import logging
from pathlib import Path
from typing import Any, Dict, List

from celery import shared_task
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType, NameEmail

from src.apps.core.celery_app import celery_app  # noqa: F401 — registers the configured app so shared_task binds to it
from src.apps.core.config import settings

logger = logging.getLogger(__name__)

# Default template directory — IAM templates (auth emails).
# Other modules pass their own *template_dir* when calling this task.
TEMPLATE_DIR = Path(__file__).resolve().parent.parent.parent / "apps" / "iam" / "templates"


@shared_task(name="send_email_task")
def send_email_task(
    subject: str,
    recipients: List[Dict[str, str]],
    template_name: str,
    context: Dict[str, Any],
    template_dir: str | None = None,
) -> bool:
    """
    Core SMTP email sender Celery task.

    *template_dir* lets calling modules supply their own Jinja2 template
    folder (defaults to the IAM templates directory).
    """
    resolved_dir = Path(template_dir) if template_dir else TEMPLATE_DIR

    if not settings.EMAIL_ENABLED:
        if settings.DEBUG:
            sep = "=" * 60
            lines = [
                "",
                sep,
                "  📧  DEV EMAIL (not sent)",
                sep,
                f"  To      : {', '.join(r['email'] for r in recipients)}",
                f"  Subject : {subject}",
                f"  Template: {template_name}",
            ]
            url_keys = ("reset_url", "verification_url", "whitelist_url", "blacklist_url")
            for key in url_keys:
                value = context.get(key)
                if value:
                    lines.append(f"  {key:<18}: {value}")
                    if "?t=" in value:
                        lines.append(f"  {'token':<18}: {value.split('?t=', 1)[1]}")
            lines += [sep, ""]
            print("\n".join(lines), flush=True)
        else:
            logger.info(
                "Email skipped (EMAIL_ENABLED=False): Subject: %s, Recipients: %s",
                subject,
                [r["email"] for r in recipients],
            )
        return True

    try:
        conf = ConnectionConfig(
            MAIL_USERNAME=settings.EMAIL_HOST_USER,
            MAIL_PASSWORD=settings.EMAIL_HOST_PASSWORD,
            MAIL_FROM=settings.EMAIL_FROM_ADDRESS,
            MAIL_PORT=int(settings.EMAIL_PORT),
            MAIL_SERVER=settings.EMAIL_HOST,
            MAIL_STARTTLS=True,
            MAIL_SSL_TLS=False,
            USE_CREDENTIALS=True,
            VALIDATE_CERTS=True,
            TEMPLATE_FOLDER=resolved_dir,
        )
        recipient_objects = [NameEmail(name=r.get("name", ""), email=r["email"]) for r in recipients]
        message = MessageSchema(
            subject=subject,
            recipients=recipient_objects,
            template_body=context,
            subtype=MessageType.html,
        )
        import asyncio
        fm = FastMail(conf)
        asyncio.run(fm.send_message(message, template_name=f"emails/{template_name}.html"))
        logger.info("Email sent: Subject=%s Recipients=%s", subject, [r["email"] for r in recipients])
        return True
    except Exception as exc:
        logger.error("Failed to send email: %s", exc)
        return False

