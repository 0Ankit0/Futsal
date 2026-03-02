"""
Central PostHog analytics client for server-side event tracking.

Usage:
    from src.apps.core.analytics import analytics

    analytics.track(
        distinct_id=str(user.id),
        event="booking_confirmed",
        properties={"booking_id": booking.id, "ground_id": booking.ground_id, "amount": 1500},
    )

Set POSTHOG_API_KEY and POSTHOG_ENABLED=true in .env to activate.
When disabled (default), all calls are silent no-ops — no overhead.
"""

import logging
from typing import Any

from posthog import Posthog

from src.apps.core.config import settings

logger = logging.getLogger(__name__)


class _Analytics:
    """Thin wrapper around the PostHog Python client with safe no-op behaviour."""

    _client: Posthog | None = None

    def _get_client(self) -> Posthog | None:
        if not settings.POSTHOG_ENABLED or not settings.POSTHOG_API_KEY:
            return None
        if self._client is None:
            self._client = Posthog(
                project_api_key=settings.POSTHOG_API_KEY,
                host=settings.POSTHOG_HOST,
                # Disable the built-in super-noisy debug logs
                debug=False,
            )
        return self._client

    def track(
        self,
        distinct_id: str,
        event: str,
        properties: dict[str, Any] | None = None,
    ) -> None:
        """Capture a server-side event. Silent no-op when PostHog is disabled."""
        client = self._get_client()
        if client is None:
            return
        try:
            client.capture(
                distinct_id=distinct_id,
                event=event,
                properties=properties or {},
            )
        except Exception:
            # Never crash the app because of analytics
            logger.debug("PostHog capture failed for event '%s'", event, exc_info=True)

    def identify(
        self,
        distinct_id: str,
        properties: dict[str, Any] | None = None,
    ) -> None:
        """Set person properties. Silent no-op when PostHog is disabled."""
        client = self._get_client()
        if client is None:
            return
        try:
            client.identify(distinct_id=distinct_id, properties=properties or {})
        except Exception:
            logger.debug("PostHog identify failed for user '%s'", distinct_id, exc_info=True)

    def group(
        self,
        distinct_id: str,
        group_type: str,
        group_key: str,
        properties: dict[str, Any] | None = None,
    ) -> None:
        """Associate a user with a group (e.g. ground_owner → tenant)."""
        client = self._get_client()
        if client is None:
            return
        try:
            client.group_identify(
                group_type=group_type,
                group_key=group_key,
                properties=properties or {},
            )
            # Also send a $groupidentify event on the user's stream
            client.capture(
                distinct_id=distinct_id,
                event="$groupidentify",
                properties={
                    "$group_type": group_type,
                    "$group_key": group_key,
                    "$group_set": properties or {},
                },
            )
        except Exception:
            logger.debug("PostHog group failed", exc_info=True)

    def shutdown(self) -> None:
        """Flush and close the PostHog client. Call on app shutdown."""
        if self._client is not None:
            try:
                self._client.shutdown()
            except Exception:
                pass


# Singleton — import this everywhere
analytics = _Analytics()
