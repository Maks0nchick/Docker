from unittest.mock import ANY

import pytest

pytestmark = pytest.mark.asyncio


async def test_create_user(test_client):
    response = await test_client.post("/users/", json={"name": "John Doe"})
    assert response.status_code == 200
    assert response.json() == {"id": ANY, "name": "John Doe"}


async def test_read_users(test_client, user):
    response = await test_client.get("/users/")
    assert response.status_code == 200
    assert len(response.json()) == 1


async def test_read_user(test_client, user):
    response = await test_client.get(f"/users/{user.id}")
    assert response.status_code == 200
    assert response.json() == {"id": user.id, "name": user.name}


async def test_update_user(test_client, user):
    response = await test_client.patch(f"/users/{user.id}", json={"name": "My Name"})
    assert response.status_code == 200
    assert response.json() == {"id": user.id, "name": "My Name"}


async def test_delete_user(test_client, user):
    response = await test_client.delete(f"/users/{user.id}")
    assert response.status_code == 200
    assert response.json() == {"detail": "User deleted"}


async def test_read_nonexistent_user(test_client, user):
    response = await test_client.get(f"/users/{user.id - 1}")
    assert response.status_code == 404
