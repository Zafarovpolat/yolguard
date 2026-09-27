"""Прямые эндпоинты ИИ-сервиса (контракт). Сейчас — заглушки; реальные модели подключат по API."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.dependencies import get_current_user
from app.models import User
from app.services import ai_client

router = APIRouter(prefix="/api/ai", tags=["ai (mock)"])


class DamageRequest(BaseModel):
    evidence_ids: list[int] = []


@router.post("/damage")
async def damage(req: DamageRequest, user: User = Depends(get_current_user)):
    return await ai_client.estimate_damage(req.evidence_ids)


@router.get("/ocr/{category}")
async def ocr(category: str, user: User = Depends(get_current_user)):
    return await ai_client.ocr_document(category)
