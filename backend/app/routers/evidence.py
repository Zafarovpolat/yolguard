"""Загрузка доказательств: сохранение файла, SHA-256 оригинала, проверка качества (ИИ-заглушка)."""
import hashlib
import os
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.dependencies import get_db, get_current_user
from app.models import User, AccidentCase, Evidence
from app.schemas import EvidenceResponse
from app.services.ai_client import check_photo_quality

router = APIRouter(prefix="/api/cases/{case_id}/evidence", tags=["evidence"])


async def _case_for_user(case_id: int, user: User, db: AsyncSession) -> AccidentCase:
    case = (await db.execute(
        select(AccidentCase).where(AccidentCase.id == case_id)
        .options(selectinload(AccidentCase.participants))
    )).scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Дело не найдено")
    if user.id != case.creator_id and user.id not in {p.user_id for p in case.participants}:
        raise HTTPException(403, "Нет доступа к этому делу")
    return case


@router.get("", response_model=list[EvidenceResponse])
async def list_evidence(
    case_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    await _case_for_user(case_id, user, db)
    rows = (await db.execute(select(Evidence).where(Evidence.case_id == case_id))).scalars().all()
    return list(rows)


@router.post("", response_model=EvidenceResponse, status_code=201)
async def upload_evidence(
    case_id: int,
    file: UploadFile = File(...),
    category: str = Form(...),              # scene | vehicle_a | plate_b | damage | license ...
    kind: str = Form("photo"),              # photo | video | document
    gps_lat: float | None = Form(None),
    gps_lng: float | None = Form(None),
    captured_at: datetime | None = Form(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _case_for_user(case_id, user, db)

    content = await file.read()
    sha256 = hashlib.sha256(content).hexdigest()  # хеш оригинала — целостность/антифрод

    case_dir = os.path.join(settings.UPLOAD_DIR, f"case_{case_id}")
    os.makedirs(case_dir, exist_ok=True)
    safe_name = f"{sha256[:16]}_{os.path.basename(file.filename or 'file')}"
    path = os.path.join(case_dir, safe_name)
    with open(path, "wb") as f:
        f.write(content)

    # Проверка качества снимка (сейчас — заглушка ИИ, позже реальная модель по API)
    quality = await check_photo_quality(file.filename or "", len(content))

    ev = Evidence(
        case_id=case_id, uploaded_by=user.id, kind=kind, category=category,
        file_path=path, sha256=sha256, gps_lat=gps_lat, gps_lng=gps_lng,
        captured_at=captured_at,
        quality_status=quality["status"],
        quality_reason="; ".join(quality["issues"]) or None,
    )
    db.add(ev)
    await db.commit()
    await db.refresh(ev)
    return ev
