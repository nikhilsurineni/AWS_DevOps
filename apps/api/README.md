# OrderFlow API

FastAPI and SQLAlchemy implementation of the OrderFlow REST, persistence, state-machine, and local WebSocket contracts.

## Run locally

```bash
python -m pip install -r requirements-dev.txt
alembic upgrade head
uvicorn orderflow_api.main:app --reload
pytest
```

The default database is `sqlite:///./orderflow.db`. Set `ORDERFLOW_DATABASE_URL` to a PostgreSQL SQLAlchemy URL for PostgreSQL. Runtime configuration is server-side and must never be committed with credentials.
