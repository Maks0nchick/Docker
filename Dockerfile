#MULTI STAGE BUILD - два этапа:

#Этап 1: 
#Версия
FROM python:3.11-alpine as builder
#Создание проекта
WORKDIR /project 
# Устанавливаем необходимые системные зависимости, чтобы можно было собирать Python-библиотеки
RUN apk add --no-cache \
# базовые компиляторы и make
    build-base \           
# для cryptography и других библиотек
    libffi-dev \      
# компилятор C     
    gcc \                 
# стандартная C-библиотека для Linux
    musl-dev \       
# заголовки для работы с PostgreSQL (psycopg2)     
    postgresql-dev \    
# OpenSSL для безопасных соединений
    openssl-dev
# Копируем pyproject.toml (зависимости) в контейнер
COPY pyproject.toml ./
# Обновляем pip и устанавливаем зависимости (включая тестовые)
RUN pip install --upgrade pip && pip install .[test]

COPY . .

# Этап 2: финальный образ — чистый, только с нужными runtime-библиотеками
FROM python:3.11-alpine

# Устанавливаем только необходимые для запуска библиотеки (не для сборки)
RUN apk add --no-cache \
    postgresql-libs     

# Создаём непривилегированного пользователя
RUN adduser -m appuser

#Создаём рабочую дерикторию
WORKDIR /project

# Копируем собранный проект из builder-контейнера
COPY --from=builder /project /project

# Устанавливаем зависимости без dev и тестовых библиотек
RUN pip install --no-cache-dir .

# Запуск от имени безопасного пользователя
USER appuser

# Команда запуска FastAPI-приложения через uvicorn
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8070"]


