FROM python:3.12-slim AS test

WORKDIR /app
COPY pyproject.toml README.md ./
COPY src ./src
COPY tests ./tests
COPY alembic.ini ./
COPY alembic ./alembic
RUN python -m pip install --no-cache-dir ".[dev]"

CMD ["pytest"]


FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ORDERFLOW_DATABASE_URL=sqlite:////tmp/orderflow.db

WORKDIR /app
COPY pyproject.toml README.md ./
COPY src ./src
COPY alembic.ini ./
COPY alembic ./alembic
RUN python -m pip install --no-cache-dir . && \
    addgroup --system orderflow && adduser --system --ingroup orderflow orderflow

USER orderflow
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=2)"]

CMD ["uvicorn", "orderflow_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
