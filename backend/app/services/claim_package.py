"""Сборка структурированного пакета для страховой (claim package).

Собирает данные дела, участников, ТС и доказательства (с хешами) в единый JSON.
Генерация PDF — отдельным шагом позже; сейчас — машиночитаемый пакет + человекочитаемая сводка.
"""
from __future__ import annotations
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AccidentCase, CaseParticipant, Vehicle, Evidence
from app.rules_engine import RULES_VERSION


async def build_claim_package(case: AccidentCase, db: AsyncSession) -> dict:
    participants = (await db.execute(
        select(CaseParticipant).where(CaseParticipant.case_id == case.id)
    )).scalars().all()

    vehicle_ids = [p.vehicle_id for p in participants if p.vehicle_id]
    vehicles = {}
    if vehicle_ids:
        rows = (await db.execute(select(Vehicle).where(Vehicle.id.in_(vehicle_ids)))).scalars().all()
        vehicles = {v.id: v for v in rows}

    evidence = (await db.execute(
        select(Evidence).where(Evidence.case_id == case.id)
    )).scalars().all()

    def vehicle_dict(vid: int | None) -> dict | None:
        v = vehicles.get(vid) if vid else None
        if not v:
            return None
        return {
            "make": v.make, "model": v.model, "year": v.year, "plate": v.plate,
            "vin": v.vin, "color": v.color,
            "insurance_company": v.insurance_company, "policy_number": v.policy_number,
        }

    return {
        "package_version": "1.0",
        "rules_version": RULES_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "case": {
            "id": case.id,
            "status": case.status,
            "eligibility": case.eligibility,
            "occurred_at": case.occurred_at.isoformat() if case.occurred_at else None,
            "location": {"lat": case.location_lat, "lng": case.location_lng, "address": case.address},
            "sobriety_required": case.sobriety_required,
            "sobriety_status": case.sobriety_status,
        },
        "participants": [
            {
                "role": p.role,
                "accepts_fault": p.accepts_fault,
                "confirmed": p.confirmed,
                "vehicle": vehicle_dict(p.vehicle_id),
            }
            for p in participants
        ],
        "diagram": case.diagram,
        "evidence": [
            {
                "id": e.id, "kind": e.kind, "category": e.category,
                "sha256": e.sha256, "quality_status": e.quality_status,
                "gps": {"lat": e.gps_lat, "lng": e.gps_lng},
                "captured_at": e.captured_at.isoformat() if e.captured_at else None,
            }
            for e in evidence
        ],
        "integrity_note": "Хеши SHA-256 фиксируют оригиналы медиа; изменение файла ломает хеш.",
    }
