"""CRUD профиля «Моя машина»."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user
from app.models import User, Vehicle
from app.schemas import VehicleCreate, VehicleUpdate, VehicleResponse

router = APIRouter(prefix="/api/vehicles", tags=["vehicles"])


async def _get_owned(vehicle_id: int, user: User, db: AsyncSession) -> Vehicle:
    v = (await db.execute(
        select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.owner_id == user.id)
    )).scalar_one_or_none()
    if not v:
        raise HTTPException(404, "Авто не найдено")
    return v


@router.get("", response_model=list[VehicleResponse])
async def list_vehicles(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(select(Vehicle).where(Vehicle.owner_id == user.id))).scalars().all()
    return list(rows)


@router.post("", response_model=VehicleResponse, status_code=201)
async def create_vehicle(
    data: VehicleCreate, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    v = Vehicle(owner_id=user.id, **data.model_dump())
    db.add(v)
    await db.commit()
    await db.refresh(v)
    return v


@router.patch("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: int, data: VehicleUpdate,
    user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    v = await _get_owned(vehicle_id, user, db)
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(v, field, value)
    await db.commit()
    await db.refresh(v)
    return v


@router.delete("/{vehicle_id}", status_code=204)
async def delete_vehicle(
    vehicle_id: int, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)
):
    v = await _get_owned(vehicle_id, user, db)
    await db.delete(v)
    await db.commit()
