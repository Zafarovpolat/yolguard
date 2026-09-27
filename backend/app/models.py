"""SQLAlchemy-модели (стиль 2.0, Mapped). Домен: водитель, авто, авария, участники, доказательства."""
from datetime import datetime, timezone
from sqlalchemy import String, Integer, Float, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


# --- Справочники статусов (храним строками, валидируем в схемах) ---
class CaseStatus:
    DRAFT = "draft"            # черновик
    ELIGIBILITY = "eligibility"  # проверка права на Европротокол
    CAPTURING = "capturing"    # сбор фото/видео
    REVIEW = "review"          # проверка человеком / подтверждения сторон
    READY = "ready"            # пакет готов
    SUBMITTED = "submitted"    # отправлен страховой
    ESCALATED = "escalated"    # передан на ручную/официальную процедуру
    STOPPED = "stopped"        # упрощённый флоу остановлен (red)


class Eligibility:
    PENDING = "pending"
    GREEN = "green"    # можно автоматически
    YELLOW = "yellow"  # нужна проверка специалистом
    RED = "red"        # упрощённый флоу невозможен


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True)  # логин водителя
    hashed_password: Mapped[str] = mapped_column(String)
    full_name: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    vehicles: Mapped[list["Vehicle"]] = relationship(back_populates="owner", cascade="all, delete-orphan")


class Vehicle(Base):
    """Профиль «Моя машина» — центральный объект экосистемы."""
    __tablename__ = "vehicles"

    id: Mapped[int] = mapped_column(primary_key=True)
    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    make: Mapped[str] = mapped_column(String(64))          # марка
    model: Mapped[str] = mapped_column(String(64))         # модель
    year: Mapped[int | None] = mapped_column(Integer)
    plate: Mapped[str] = mapped_column(String(32), index=True)  # госномер
    vin: Mapped[str | None] = mapped_column(String(32))
    color: Mapped[str | None] = mapped_column(String(32))
    insurance_company: Mapped[str | None] = mapped_column(String(128))
    policy_number: Mapped[str | None] = mapped_column(String(64))
    policy_valid_until: Mapped[datetime | None] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    owner: Mapped["User"] = relationship(back_populates="vehicles")


class AccidentCase(Base):
    """Дело об аварии — конечный автомат от «я попал в ДТП» до пакета для страховой."""
    __tablename__ = "cases"

    id: Mapped[int] = mapped_column(primary_key=True)
    creator_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    status: Mapped[str] = mapped_column(String(24), default=CaseStatus.DRAFT)
    eligibility: Mapped[str] = mapped_column(String(12), default=Eligibility.PENDING)
    eligibility_answers: Mapped[dict | None] = mapped_column(JSON)  # ответы визарда
    eligibility_reasons: Mapped[list | None] = mapped_column(JSON)  # почему такой вердикт

    join_code: Mapped[str | None] = mapped_column(String(12), index=True)  # код для 2-го участника

    occurred_at: Mapped[datetime | None] = mapped_column(DateTime)
    location_lat: Mapped[float | None] = mapped_column(Float)
    location_lng: Mapped[float | None] = mapped_column(Float)
    address: Mapped[str | None] = mapped_column(String(512))

    sobriety_required: Mapped[bool] = mapped_column(Boolean, default=True)  # мед. освидетельствование
    sobriety_status: Mapped[str | None] = mapped_column(String(24))

    diagram: Mapped[dict | None] = mapped_column(JSON)  # схема ДТП (черновик, редактируемый)
    notes: Mapped[str | None] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_now, onupdate=_now)

    participants: Mapped[list["CaseParticipant"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )
    evidence: Mapped[list["Evidence"]] = relationship(
        back_populates="case", cascade="all, delete-orphan"
    )


class CaseParticipant(Base):
    """Сторона A или B: связывает водителя и его авто с делом."""
    __tablename__ = "case_participants"

    id: Mapped[int] = mapped_column(primary_key=True)
    case_id: Mapped[int] = mapped_column(ForeignKey("cases.id"), index=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    vehicle_id: Mapped[int | None] = mapped_column(ForeignKey("vehicles.id"))
    role: Mapped[str] = mapped_column(String(1))  # "A" | "B"
    accepts_fault: Mapped[bool] = mapped_column(Boolean, default=False)  # признаёт вину
    confirmed: Mapped[bool] = mapped_column(Boolean, default=False)      # подтвердил схему/данные
    joined_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    case: Mapped["AccidentCase"] = relationship(back_populates="participants")


class Evidence(Base):
    """Единица доказательства: фото/видео/документ + метаданные и хеш оригинала."""
    __tablename__ = "evidence"

    id: Mapped[int] = mapped_column(primary_key=True)
    case_id: Mapped[int] = mapped_column(ForeignKey("cases.id"), index=True)
    uploaded_by: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    kind: Mapped[str] = mapped_column(String(16))       # photo | video | document
    category: Mapped[str] = mapped_column(String(32))   # scene | vehicle_a | plate_b | damage | license ...
    file_path: Mapped[str] = mapped_column(String(512))
    sha256: Mapped[str | None] = mapped_column(String(64))  # хеш оригинала (целостность/антифрод)
    gps_lat: Mapped[float | None] = mapped_column(Float)
    gps_lng: Mapped[float | None] = mapped_column(Float)
    captured_at: Mapped[datetime | None] = mapped_column(DateTime)
    quality_status: Mapped[str] = mapped_column(String(12), default="pending")  # pending|ok|rejected
    quality_reason: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_now)

    case: Mapped["AccidentCase"] = relationship(back_populates="evidence")
