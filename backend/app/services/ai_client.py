"""Клиент ИИ-сервиса. СЕЙЧАС — заглушки (mock). Реальные модели подключаются по API позже.

Граница намеренно тонкая: когда появится внешний ИИ-сервис, достаточно заменить тела
функций на HTTP-вызовы (base_url из настроек) — контракт ответа остаётся прежним.
Принцип из ТЗ: ИИ даёт СИГНАЛЫ, а не выносит юридические решения.
"""
from __future__ import annotations
import os

AI_ENABLED = os.getenv("AI_SERVICE_URL") is not None  # когда зададут URL — переключимся на реальный


async def check_photo_quality(filename: str, size_bytes: int) -> dict:
    """Проверка качества снимка: размытость, темнота, читаемость номера, кадрирование.

    MOCK: сейчас — простая эвристика по размеру файла. Реальная модель заменит это.
    """
    issues: list[str] = []
    if size_bytes < 40_000:  # слишком «лёгкий» файл — вероятно, мелкий/размытый кадр
        issues.append("Снимок слишком маленький — возможно, размытый. Переснимите.")
    status = "rejected" if issues else "ok"
    return {
        "status": status,
        "issues": issues,
        "score": 0.5 if issues else 0.95,
        "mock": not AI_ENABLED,
    }


async def estimate_damage(evidence_ids: list[int]) -> dict:
    """Оценка повреждений и диапазона стоимости ремонта. MOCK."""
    return {
        "parts": ["задний бампер", "крышка багажника"],
        "repair_vs_replace": {"задний бампер": "replace", "крышка багажника": "repair"},
        "cost_range_uzs": [3_500_000, 5_100_000],
        "confidence": 0.4,
        "note": "Это ориентир, не окончательная оценка.",
        "mock": not AI_ENABLED,
    }


async def ocr_document(category: str) -> dict:
    """OCR документов (права/полис/техпаспорт). MOCK."""
    return {
        "category": category,
        "fields": {"raw_text": "(mock) распознавание подключается позже"},
        "mock": not AI_ENABLED,
    }
