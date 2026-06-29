"""Estimate reading time from body text at ~220 wpm."""
from __future__ import annotations

import re


def estimate_reading_minutes(text: str, wpm: int = 220) -> int:
    words = len(re.findall(r"\w+", text or ""))
    return max(1, round(words / wpm))
