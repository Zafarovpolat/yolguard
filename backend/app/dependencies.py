"""Зависимости FastAPI: сессия БД и текущий пользователь."""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models import User
from app.utils.security import decode_token, JWTError

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


async def get_db():
    async with AsyncSessionLocal() as session:
        yield session


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    creds_error = HTTPException(status.HTTP_401_UNAUTHORIZED, "Недействительный токен")
    try:
        payload = decode_token(token)
        phone = payload.get("sub")
    except JWTError:
        raise creds_error
    if not phone:
        raise creds_error

    user = (await db.execute(select(User).where(User.phone == phone))).scalar_one_or_none()
    if not user or not user.is_active:
        raise creds_error
    return user
