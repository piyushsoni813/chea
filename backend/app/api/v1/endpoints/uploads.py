"""File uploads. Validates extension and size, stores under UPLOAD_DIR with a
collision-proof name, records bookkeeping, and returns a servable URL.

Files are streamed to disk in chunks and the running total is checked against
the configured ceiling, so an oversized upload is rejected without first being
buffered whole in memory."""
from __future__ import annotations

import os
import uuid
from pathlib import Path

from fastapi import APIRouter, File, Form, HTTPException, UploadFile, status

from app.api.deps import CurrentUser, DbSession
from app.core.config import settings
from app.models.upload import UploadedFile
from app.schemas.upload import UploadRead

router = APIRouter(prefix="/uploads", tags=["uploads"])

_CHUNK = 1024 * 1024  # 1 MiB


@router.post("", response_model=UploadRead, status_code=201)
async def upload_file(
    user: CurrentUser,
    db: DbSession,
    file: UploadFile = File(...),
    purpose: str | None = Form(None),
) -> UploadRead:
    original = file.filename or "file"
    ext = Path(original).suffix.lower()
    allowed = {e.lower() for e in settings.ALLOWED_UPLOAD_EXTENSIONS}
    if ext not in allowed:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            f"File type '{ext or 'unknown'}' is not allowed. "
            f"Accepted: {', '.join(sorted(allowed))}",
        )

    upload_root = Path(settings.UPLOAD_DIR)
    upload_root.mkdir(parents=True, exist_ok=True)
    stored_name = f"{uuid.uuid4().hex}{ext}"
    dest = upload_root / stored_name

    max_bytes = settings.MAX_UPLOAD_MB * 1024 * 1024
    size = 0
    try:
        with dest.open("wb") as out:
            while chunk := await file.read(_CHUNK):
                size += len(chunk)
                if size > max_bytes:
                    out.close()
                    dest.unlink(missing_ok=True)
                    raise HTTPException(
                        status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                        f"File exceeds the {settings.MAX_UPLOAD_MB} MB limit",
                    )
                out.write(chunk)
    finally:
        await file.close()

    url = f"/static/{stored_name}"
    record = UploadedFile(
        uploader_id=user.id,
        original_name=original,
        stored_name=stored_name,
        url=url,
        content_type=file.content_type or "application/octet-stream",
        size_bytes=size,
        purpose=purpose,
    )
    db.add(record)
    await db.commit()
    await db.refresh(record)
    return UploadRead.model_validate(record)
