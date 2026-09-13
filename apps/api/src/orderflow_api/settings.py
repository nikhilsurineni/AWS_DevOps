from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache

ALLOWED_ENVIRONMENTS = {"local", "personal-learning", "enterprise-sandbox"}


@dataclass(frozen=True)
class Settings:
    database_url: str
    environment: str
    cors_origins: tuple[str, ...]
    log_level: str


@lru_cache
def get_settings() -> Settings:
    environment = os.getenv("ORDERFLOW_ENVIRONMENT", "local")
    if environment not in ALLOWED_ENVIRONMENTS:
        raise ValueError(
            "ORDERFLOW_ENVIRONMENT must be local, personal-learning, or enterprise-sandbox"
        )
    origins = tuple(
        value.strip()
        for value in os.getenv(
            "ORDERFLOW_CORS_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173"
        ).split(",")
        if value.strip()
    )
    return Settings(
        database_url=os.getenv("ORDERFLOW_DATABASE_URL", "sqlite:///./orderflow.db"),
        environment=environment,
        cors_origins=origins,
        log_level=os.getenv("ORDERFLOW_LOG_LEVEL", "INFO").upper(),
    )
