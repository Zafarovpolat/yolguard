"""Конфигурация приложения (Pydantic Settings, читает .env)."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # По умолчанию dev-БД на SQLite — Postgres+PostGIS подключим позже без переписывания моделей
    DATABASE_URL: str = "sqlite+aiosqlite:///./yolguard_dev.db"

    # JWT
    SECRET_KEY: str = "dev-secret-change-me"  # ОБЯЗАТЕЛЬНО переопределить в проде через .env
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # неделя (мобилка редко логинится)

    # CORS: мобильный клиент ходит по bearer-токену, cookie не нужны -> "*" безопасно
    CORS_ORIGINS: list[str] = ["*"]

    # Локальное хранилище медиа (в проде -> S3-совместимое)
    UPLOAD_DIR: str = "./uploads"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")


settings = Settings()
