# ЭТАП 1: Сборка зависимостей
FROM python:3.11-alpine as builder

# Устанавливаем системные зависимости для сборки
RUN apk add --no-cache \
    build-base \
    libffi-dev \
    gcc \
    musl-dev \
    postgresql-dev \
    openssl-dev

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем зависимости проекта
COPY pyproject.toml poetry.lock* ./

# Устанавливаем Python-зависимости (включая тестовые)
RUN pip install --upgrade pip && \
    pip install pytest && \
    pip install .[test]

# Копируем всё остальное
COPY . .

# ЭТАП 2: Финальный образ
FROM python:3.11-alpine

# Runtime зависимости
RUN apk add --no-cache postgresql-libs

# Создаём пользователя
RUN adduser -D appuser

WORKDIR /app

# Копируем только необходимое из builder-этапа
COPY --from=builder --chown=appuser:appuser /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder --chown=appuser:appuser /app /app

# Устанавливаем PATH для pytest
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Переключаемся на непривилегированного пользователя
USER appuser

# Команда по умолчанию
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8070"]
