"""Дело об аварии: создание, право (Европротокол), присоединение 2-го участника,
схема ДТП, подтверждения, мед.освидетельствование, пакет для страховой."""
import secrets

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models import User, AccidentCase, CaseParticipant, CaseStatus, Eligibility
from app.schemas import (
    CaseCreate, CaseResponse, EligibilitySubmit, EligibilityResult,
    JoinRequest, DiagramUpdate, ConfirmRequest,
)
from app.rules_engine import evaluate_eligibility, WIZARD_QUESTIONS
from app.services.claim_package import build_claim_package

router = APIRouter(prefix="/api/cases", tags=["cases"])


async def _load_case(case_id: int, db: AsyncSession) -> AccidentCase | None:
    return (await db.execute(
        select(AccidentCase)
        .where(AccidentCase.id == case_id)
        .options(selectinload(AccidentCase.participants), selectinload(AccidentCase.evidence))
    )).scalar_one_or_none()


async def _reload_case(case: AccidentCase, db: AsyncSession) -> AccidentCase:
    # expire_on_commit=False => после commit коллекции остаются «загруженными» со старым
    # содержимым, и selectinload их не перечитает. Точечно сбрасываем только связи дела
    # (не трогая, например, текущего пользователя), чтобы participants/evidence подтянулись свежими.
    db.expire(case, ["participants", "evidence"])
    return await _load_case(case.id, db)


async def _case_for_user(case_id: int, user: User, db: AsyncSession) -> AccidentCase:
    case = await _load_case(case_id, db)
    if not case:
        raise HTTPException(404, "Дело не найдено")
    participant_ids = {p.user_id for p in case.participants}
    if user.id != case.creator_id and user.id not in participant_ids:
        raise HTTPException(403, "Нет доступа к этому делу")
    return case


@router.get("/eligibility-questions")
async def eligibility_questions():
    """Вопросы визарда права — мобилка рендерит форму по этому списку."""
    return {"questions": WIZARD_QUESTIONS}


@router.get("", response_model=list[CaseResponse])
async def list_cases(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(
        select(AccidentCase)
        .where(AccidentCase.creator_id == user.id)
        .options(selectinload(AccidentCase.participants), selectinload(AccidentCase.evidence))
        .order_by(AccidentCase.created_at.desc())
    )).scalars().all()
    return list(rows)


@router.post("", response_model=CaseResponse, status_code=201)
async def create_case(
    data: CaseCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    case = AccidentCase(
        creator_id=user.id,
        status=CaseStatus.ELIGIBILITY,
        join_code=secrets.token_hex(3).upper(),  # 6-символьный код для 2-го участника
        occurred_at=data.occurred_at,
        location_lat=data.location_lat,
        location_lng=data.location_lng,
        address=data.address,
    )
    db.add(case)
    await db.flush()
    # Создатель — сторона A
    db.add(CaseParticipant(case_id=case.id, user_id=user.id, vehicle_id=data.vehicle_id, role="A"))
    await db.commit()
    return await _load_case(case.id, db)


@router.get("/{case_id}", response_model=CaseResponse)
async def get_case(
    case_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    return await _case_for_user(case_id, user, db)


@router.post("/{case_id}/eligibility", response_model=EligibilityResult)
async def submit_eligibility(
    case_id: int, data: EligibilitySubmit,
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    case = await _case_for_user(case_id, user, db)
    verdict = evaluate_eligibility(data.answers)

    case.eligibility_answers = verdict["normalized_answers"]
    case.eligibility_reasons = verdict["reasons"]
    if verdict["result"] == "green":
        case.eligibility = Eligibility.GREEN
        case.status = CaseStatus.CAPTURING  # можно собирать доказательства
    else:
        case.eligibility = Eligibility.RED
        case.status = CaseStatus.STOPPED    # упрощённый флоу остановлен
    await db.commit()
    return EligibilityResult(**{k: verdict[k] for k in ("result", "reasons", "rules_version")})


@router.post("/join", response_model=CaseResponse)
async def join_case(
    data: JoinRequest, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    """Второй водитель присоединяется по коду (из QR)."""
    case = (await db.execute(
        select(AccidentCase).where(AccidentCase.join_code == data.join_code.upper())
        .options(selectinload(AccidentCase.participants))
    )).scalar_one_or_none()
    if not case:
        raise HTTPException(404, "Код не найден")
    if any(p.user_id == user.id for p in case.participants):
        return await _load_case(case.id, db)
    if len(case.participants) >= 2:
        raise HTTPException(400, "В деле уже два участника")
    db.add(CaseParticipant(case_id=case.id, user_id=user.id, vehicle_id=data.vehicle_id, role="B"))
    await db.commit()
    return await _reload_case(case, db)


@router.put("/{case_id}/diagram", response_model=CaseResponse)
async def update_diagram(
    case_id: int, data: DiagramUpdate,
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    case = await _case_for_user(case_id, user, db)
    case.diagram = data.diagram
    # правка схемы сбрасывает подтверждения сторон
    for p in case.participants:
        p.confirmed = False
    await db.commit()
    return await _load_case(case.id, db)


@router.post("/{case_id}/confirm", response_model=CaseResponse)
async def confirm_case(
    case_id: int, data: ConfirmRequest,
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db),
):
    """Участник подтверждает схему и данные (и, при необходимости, признание вины)."""
    case = await _case_for_user(case_id, user, db)
    me = next((p for p in case.participants if p.user_id == user.id), None)
    if not me:
        raise HTTPException(403, "Вы не участник дела")
    me.confirmed = True
    if data.accepts_fault is not None:
        me.accepts_fault = data.accepts_fault
    # когда все участники (2) подтвердили — переходим к проверке/готовности
    if len(case.participants) >= 2 and all(p.confirmed for p in case.participants):
        case.status = CaseStatus.REVIEW
    await db.commit()
    return await _load_case(case.id, db)


@router.post("/{case_id}/claim-package")
async def claim_package(
    case_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    case = await _case_for_user(case_id, user, db)
    if case.eligibility != Eligibility.GREEN:
        raise HTTPException(400, "Дело не прошло проверку права на упрощённый порядок")
    package = await build_claim_package(case, db)
    case.status = CaseStatus.READY
    await db.commit()
    return package
