import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import AsyncSessionLocal, init_db as create_tables
from src.main import app
from src.models import User


@pytest_asyncio.fixture(scope="session")
async def init_db() -> None:
    await create_tables()


@pytest_asyncio.fixture(scope='function')
async def db() -> AsyncSession:
    async with AsyncSessionLocal() as session:
        yield session


@pytest_asyncio.fixture(autouse=True)
async def test_client():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        yield client


@pytest_asyncio.fixture(autouse=True)
async def clear_table(init_db, db: AsyncSession) -> None:
    await db.execute(text("TRUNCATE users;"))
    await db.commit()


@pytest_asyncio.fixture
async def user(db: AsyncSession) -> User:
    user = User(name="John Doe")
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
