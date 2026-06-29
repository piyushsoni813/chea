"""Pytest fixtures: a transactional async client backed by the test database.

Every test runs inside a transaction that is rolled back afterwards, so tests
stay isolated and never leave residue. All async fixtures and tests share one
session-scoped event loop, because asyncpg connections are bound to the loop
that created them.

Point the suite at a throwaway database via the usual POSTGRES_* settings
(ideally POSTGRES_DB=chea_test). PostgreSQL is required: the models use ARRAY,
JSONB and native UUID columns that SQLite cannot represent.
"""
from __future__ import annotations

from collections.abc import AsyncGenerator

import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.api.deps import get_db
from app.core.config import settings
from app.db.base import Base
from app.main import app

engine = create_async_engine(settings.database_url, future=True)
TestingSessionLocal = async_sessionmaker(engine, expire_on_commit=False)


@pytest_asyncio.fixture(scope="session", loop_scope="session", autouse=True)
async def _schema() -> AsyncGenerator[None, None]:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture(loop_scope="session")
async def db() -> AsyncGenerator[AsyncSession, None]:
    """A session wrapped in a transaction that is rolled back after each test."""
    connection = await engine.connect()
    trans = await connection.begin()
    # create_savepoint => an endpoint's commit() releases a savepoint instead of
    # the outer transaction, so the rollback below still wipes the test's writes.
    session = AsyncSession(
        bind=connection, expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    try:
        yield session
    finally:
        await session.close()
        await trans.rollback()
        await connection.close()


@pytest_asyncio.fixture(loop_scope="session")
async def client(db: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db

    app.dependency_overrides[get_db] = _override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
