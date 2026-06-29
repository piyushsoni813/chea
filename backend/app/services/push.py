"""Firebase Cloud Messaging push delivery.

Lazily initialises the Firebase Admin SDK from a service-account file. If no
credentials are configured, pushes are logged and skipped rather than raising,
which keeps notification creation working in development.
"""
from __future__ import annotations

import logging

from app.core.config import settings

logger = logging.getLogger(__name__)

_initialised = False
_messaging = None


def _ensure_init() -> bool:
    global _initialised, _messaging
    if _initialised:
        return _messaging is not None
    _initialised = True
    if not settings.FCM_CREDENTIALS_PATH:
        logger.info("FCM not configured; push notifications will be logged only")
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        cred = credentials.Certificate(settings.FCM_CREDENTIALS_PATH)
        if not firebase_admin._apps:
            firebase_admin.initialize_app(cred)
        _messaging = messaging
        return True
    except Exception as exc:  # noqa: BLE001
        logger.error("Failed to initialise FCM: %s", exc)
        return False


def send_push(tokens: list[str], title: str, body: str, data: dict | None = None) -> None:
    if not tokens:
        return
    if not _ensure_init():
        logger.info("Push (mock) -> %d device(s): %s", len(tokens), title)
        return
    messaging = _messaging
    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in (data or {}).items()},
        tokens=tokens,
    )
    try:
        response = messaging.send_each_for_multicast(message)
        logger.info("Push sent: %d ok, %d failed", response.success_count, response.failure_count)
    except Exception as exc:  # noqa: BLE001
        logger.error("Push send failed: %s", exc)
