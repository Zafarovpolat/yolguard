"""Pydantic-схемы (v2) запросов/ответов."""
from datetime import datetime
from typing import Any
from pydantic import BaseModel, ConfigDict, Field


# --- Auth ---
class UserCreate(BaseModel):
    phone: str = Field(min_length=6, max_length=32)
    password: str = Field(min_length=6, max_length=128)
    full_name: str | None = None


class LoginRequest(BaseModel):
    phone: str
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    phone: str
    full_name: str | None
    created_at: datetime


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


# --- Vehicles ---
class VehicleCreate(BaseModel):
    make: str
    model: str
    year: int | None = None
    plate: str
    vin: str | None = None
    color: str | None = None
    insurance_company: str | None = None
    policy_number: str | None = None
    policy_valid_until: datetime | None = None


class VehicleUpdate(BaseModel):
    make: str | None = None
    model: str | None = None
    year: int | None = None
    plate: str | None = None
    vin: str | None = None
    color: str | None = None
    insurance_company: str | None = None
    policy_number: str | None = None
    policy_valid_until: datetime | None = None


class VehicleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    make: str
    model: str
    year: int | None
    plate: str
    vin: str | None
    color: str | None
    insurance_company: str | None
    policy_number: str | None
    policy_valid_until: datetime | None
    created_at: datetime


# --- Cases ---
class CaseCreate(BaseModel):
    vehicle_id: int | None = None  # авто создателя (сторона A)
    occurred_at: datetime | None = None
    location_lat: float | None = None
    location_lng: float | None = None
    address: str | None = None


class EligibilitySubmit(BaseModel):
    answers: dict[str, Any]


class EligibilityResult(BaseModel):
    result: str
    reasons: list[dict[str, Any]]
    rules_version: str


class JoinRequest(BaseModel):
    join_code: str
    vehicle_id: int | None = None


class DiagramUpdate(BaseModel):
    diagram: dict[str, Any]


class ConfirmRequest(BaseModel):
    accepts_fault: bool | None = None


class ParticipantResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    user_id: int | None
    vehicle_id: int | None
    role: str
    accepts_fault: bool
    confirmed: bool


class EvidenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    kind: str
    category: str
    file_path: str
    sha256: str | None
    quality_status: str
    quality_reason: str | None
    captured_at: datetime | None
    created_at: datetime


class CaseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    creator_id: int
    status: str
    eligibility: str
    join_code: str | None
    occurred_at: datetime | None
    location_lat: float | None
    location_lng: float | None
    address: str | None
    sobriety_required: bool
    sobriety_status: str | None
    diagram: dict[str, Any] | None
    created_at: datetime
    participants: list[ParticipantResponse] = []
    evidence: list[EvidenceResponse] = []
