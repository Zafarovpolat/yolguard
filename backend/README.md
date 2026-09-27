# Yo'lGuard AI — Backend (MVP)

FastAPI + async SQLAlchemy. Dev-БД: SQLite (`yolguard_dev.db`), прод: PostgreSQL + PostGIS.

## Запуск (dev)
```bash
cd backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
- Swagger: http://localhost:8000/docs
- Health: http://localhost:8000/health
- Хост `0.0.0.0` — чтобы мобилка с телефона видела бэкенд по IP компьютера в той же сети.

## Что уже есть (ядро аварии)
- **Auth** (`/api/auth`): регистрация/логин по телефону + JWT.
- **Vehicles** (`/api/vehicles`): профиль «Моя машина» (CRUD).
- **Cases** (`/api/cases`):
  - визард права на Европротокол (`GET /eligibility-questions`, `POST /{id}/eligibility`)
    — **детерминированный** движок (`app/rules_engine.py`), без ИИ;
  - присоединение 2-го участника по коду/QR (`POST /join`);
  - схема ДТП (`PUT /{id}/diagram`), подтверждения сторон (`POST /{id}/confirm`);
  - пакет для страховой (`POST /{id}/claim-package`).
- **Evidence** (`/api/cases/{id}/evidence`): загрузка фото/видео/документов,
  SHA-256 оригинала, проверка качества (ИИ-заглушка).
- **AI** (`/api/ai`): контракт ИИ-сервиса — **сейчас заглушки**. Реальные модели
  подключаются по API: задать `AI_SERVICE_URL` в `.env` и заменить тела функций в
  `app/services/ai_client.py` на HTTP-вызовы (контракт ответа не меняется).

## Переезд на Postgres
В `.env` заменить `DATABASE_URL` на `postgresql://user:pass@host/db`
(драйвер asyncpg подставится автоматически) и прогнать alembic.

## Структура
```
app/
  main.py           config.py        database.py      dependencies.py
  models.py         schemas.py       rules_engine.py  (движок права)
  routers/          auth vehicles cases evidence ai
  services/         claim_package.py  ai_client.py
  utils/            security.py
```
