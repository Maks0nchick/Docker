# ЭТАП 1: Сборка (build stage)
FROM python:3.11-alpine as builder

# Устанавливаем рабочую директорию
WORKDIR /app

# Устанавливаем зависимости, нужные для сборки Python-библиотек
RUN apk add --no-cache \
    build-base \           # компиляторы, make
    libffi-dev \           # для cryptography
    gcc \                  # C-компилятор
    musl-dev \             # стандартная C-библиотека
    postgresql-dev \       # psycopg2 (PostgreSQL)
    openssl-dev            # SSL-поддержка

# Копируем зависимости проекта
COPY pyproject.toml ./

# Обновляем pip и устанавливаем зависимости (включая тестовые)
RUN pip install --upgrade pip && pip install .[test]

# Копируем остальной код проекта
COPY . .



# ЭТАП 2: Финальный образ
FROM python:3.11-alpine

# Устанавливаем только библиотеки, нужные для запуска
RUN apk add --no-cache \
    postgresql-libs       # для psycopg2

# Создаём непривилегированного пользователя
RUN adduser -D appuser   

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем всё из builder-образа
COPY --from=builder /app /app

# Устанавливаем зависимости (только runtime, без dev)
RUN pip install --no-cache-dir .

# Используем безопасного пользователя
USER appuser

# Команда запуска FastAPI-приложения
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8070"]
