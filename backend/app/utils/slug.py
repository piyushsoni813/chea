"""Slug generation with collision-avoiding suffixes."""
from __future__ import annotations

import re
import secrets

_slug_re = re.compile(r"[^a-z0-9]+")


def slugify(text: str) -> str:
    base = _slug_re.sub("-", text.lower()).strip("-")
    return base or "item"


def unique_slug(text: str) -> str:
    return f"{slugify(text)}-{secrets.token_hex(3)}"
