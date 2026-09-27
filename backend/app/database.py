"""Асинхронный слой БД. Поддерживает SQLite (dev) и PostgreSQL (prod)."""
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


def _normalize_url(url: str) -> str:
    """Подставляем async-драйвер в зависимости от СУБД."""
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    if url.startswith("sqlite://"):
        return url.replace("sqlite://", "sqlite+aiosqlite://", 1)
    return url  # уже с драйвером (sqlite+aiosqlite / postgresql+asyncpg)


engine = create_async_engine(_normalize_url(settings.DATABASE_URL), pool_pre_ping=True)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def init_db() -> None:
    """Создать таблицы (для dev; в проде — alembic)."""
    from app import models  # noqa: F401 — регистрируем модели в метаданных

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
