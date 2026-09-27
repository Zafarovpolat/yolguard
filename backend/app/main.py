"""Yo'lGuard AI — backend (MVP). FastAPI + async SQLAlchemy (SQLite dev / Postgres prod)."""
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.routers import auth, vehicles, cases, evidence, ai


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()  # dev: создаём таблицы; в проде — alembic
    yield


app = FastAPI(title="Yo'lGuard AI API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=False,  # мобилка ходит по bearer-токену, cookie не используем
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(vehicles.router)
app.include_router(cases.router)
app.include_router(evidence.router)
app.include_router(ai.router)


@app.get("/health", tags=["system"])
async def health():
    return {"status": "ok", "service": "yolguard-api"}
