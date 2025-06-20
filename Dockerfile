# ЭТАП 1: Сборка зависимостей
FROM python:3.11-alpine as builder

# Устанавливаем рабочую директорию
WORKDIR /app

# Устанавливаем системные зависимости для сборки Python-библиотек
RUN apk add --no-cache \
    build-base \          
    libffi-dev \          
    gcc \                 
    musl-dev \            
    postgresql-dev \      
    openssl-dev           

# Копируем зависимости проекта
COPY pyproject.toml ./

# Устанавливаем Python-зависимости с тестовыми (если указаны в pyproject.toml)
RUN pip install --upgrade pip && pip install .[test]

# Копируем всё остальное (код, тесты, и т.д.)
COPY . .



# ЭТАП 2: Финальный образ (для запуска)
FROM python:3.11-alpine

# Устанавливаем только runtime-зависимости
RUN apk add --no-cache \
    postgresql-libs       # для работы с PostgreSQL

# Создаём непривилегированного пользователя
RUN adduser -D appuser

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем всё из builder-контейнера
COPY --from=builder /app /app

# Устанавливаем Python-зависимости (без dev и test)
RUN pip install --no-cache-dir .

# Запускаем от имени безопасного пользователя
USER appuser

# Команда запуска FastAPI-приложения через uvicorn
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8070"]
