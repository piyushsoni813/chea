"""Contact directory grouped by category (council, placement, lab staff, office)."""
from __future__ import annotations

import uuid

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import delete, func, or_, select

from app.api.deps import AdminUser, DbSession, Pagination
from app.models.faculty import Contact
from app.schemas.common import Message, Page
from app.schemas.faculty import ContactCreate, ContactRead, ContactUpdate

router = APIRouter(prefix="/contacts", tags=["contacts"])


@router.get("", response_model=Page[ContactRead])
async def list_contacts(
    db: DbSession, pg: Pagination,
    category: str | None = None, q: str | None = None,
) -> Page[ContactRead]:
    stmt = select(Contact)
    if category:
        stmt = stmt.where(Contact.category == category)
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(
            Contact.name.ilike(like),
            Contact.role.ilike(like),
            Contact.email.ilike(like),
        ))
    total = await db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = (await db.scalars(
        stmt.order_by(Contact.category, Contact.display_order, Contact.name)
        .offset(pg.offset).limit(pg.size)
    )).all()
    items = [ContactRead.model_validate(r) for r in rows]
    return Page.create(items, total or 0, pg.page, pg.size)


@router.post("", response_model=ContactRead, status_code=201)
async def create_contact(data: ContactCreate, user: AdminUser, db: DbSession) -> ContactRead:
    contact = Contact(**data.model_dump())
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return ContactRead.model_validate(contact)


@router.patch("/{contact_id}", response_model=ContactRead)
async def update_contact(contact_id: uuid.UUID, data: ContactUpdate,
                         user: AdminUser, db: DbSession) -> ContactRead:
    contact = await db.scalar(select(Contact).where(Contact.id == contact_id))
    if not contact:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contact not found")
    for f, v in data.model_dump(exclude_unset=True).items():
        setattr(contact, f, v)
    await db.commit()
    await db.refresh(contact)
    return ContactRead.model_validate(contact)


@router.delete("/{contact_id}", response_model=Message)
async def delete_contact(contact_id: uuid.UUID, user: AdminUser, db: DbSession) -> Message:
    await db.execute(delete(Contact).where(Contact.id == contact_id))
    await db.commit()
    return Message(detail="Contact removed")
