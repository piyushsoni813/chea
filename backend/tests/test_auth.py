"""Authentication and profile flows."""
import pytest

pytestmark = pytest.mark.asyncio(loop_scope="session")


async def _register(client, email="alice@students.chea.edu"):
    return await client.post("/api/v1/auth/register", json={
        "email": email, "password": "secret123",
        "full_name": "Alice Student", "roll_number": "CH22B042", "semester": 4,
    })


async def test_register_returns_tokens(client):
    r = await _register(client)
    assert r.status_code == 201
    body = r.json()
    assert body["access_token"] and body["refresh_token"]
    assert body["token_type"].lower() == "bearer"


async def test_register_rejects_disallowed_domain(client):
    r = await client.post("/api/v1/auth/register", json={
        "email": "someone@gmail.com", "password": "secret123",
        "full_name": "Outsider",
    })
    assert r.status_code == 400


async def test_register_then_duplicate_is_conflict(client):
    await _register(client, "bob@students.chea.edu")
    r = await _register(client, "bob@students.chea.edu")
    assert r.status_code in (400, 409)


async def test_login_and_me(client):
    await _register(client, "carol@students.chea.edu")
    r = await client.post("/api/v1/auth/login", json={
        "email": "carol@students.chea.edu", "password": "secret123"})
    assert r.status_code == 200
    token = r.json()["access_token"]
    me = await client.get("/api/v1/auth/me",
                          headers={"Authorization": f"Bearer {token}"})
    assert me.status_code == 200
    assert me.json()["email"] == "carol@students.chea.edu"
    assert me.json()["role"] == "student"


async def test_wrong_password_is_unauthorized(client):
    await _register(client, "dave@students.chea.edu")
    r = await client.post("/api/v1/auth/login", json={
        "email": "dave@students.chea.edu", "password": "wrongpass"})
    assert r.status_code == 401


async def test_refresh_rotates_tokens(client):
    reg = await _register(client, "erin@students.chea.edu")
    refresh = reg.json()["refresh_token"]
    r = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert r.status_code == 200
    assert r.json()["access_token"]
    # The old refresh token should no longer work after rotation.
    again = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh})
    assert again.status_code == 401


async def test_protected_route_requires_auth(client):
    r = await client.get("/api/v1/auth/me")
    assert r.status_code == 401
