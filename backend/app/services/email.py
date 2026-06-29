"""SMTP email sending.

When SMTP is not configured (the common local-dev case) the email is logged
instead of sent, so background tasks never crash a fresh environment.
"""
from __future__ import annotations

import logging
import smtplib
from email.mime.text import MIMEText

from app.core.config import settings

logger = logging.getLogger(__name__)


def send_email(to: str, subject: str, body: str) -> None:
    if not settings.SMTP_HOST:
        logger.info("SMTP not configured; would email %s: %s", to, subject)
        return
    msg = MIMEText(body, "html")
    msg["Subject"] = subject
    msg["From"] = settings.SMTP_FROM
    msg["To"] = to
    try:
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=10) as server:
            if settings.SMTP_TLS:
                server.starttls()
            if settings.SMTP_USER and settings.SMTP_PASSWORD:
                server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_FROM, [to], msg.as_string())
        logger.info("Sent email to %s", to)
    except Exception as exc:  # noqa: BLE001 - email must never break the request
        logger.error("Failed to send email to %s: %s", to, exc)
