from __future__ import annotations

import json
import logging
from contextlib import asynccontextmanager
from uuid import UUID, uuid4

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request, Response, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.orm import Session
from starlette.websockets import WebSocketDisconnect

from .database import get_session, init_database
from .domain import OrderStatus
from .schemas import (
    HealthResponse,
    OrderCreate,
    OrderDetail,
    OrderEventRead,
    OrderSummary,
    TransitionRequest,
)
from .service import (
    EventConflictError,
    InvalidTransitionError,
    OrderNotFoundError,
    apply_transition,
    create_order,
    get_order,
    list_orders,
)
from .settings import get_settings
from .stream import ConnectionManager

settings = get_settings()
logging.basicConfig(level=settings.log_level, format="%(message)s")
logger = logging.getLogger("orderflow")
manager = ConnectionManager()


def safe_uuid(value: str | None, header_name: str) -> str:
    if value is None:
        return str(uuid4())
    try:
        return str(UUID(value))
    except ValueError:
        raise HTTPException(status_code=400, detail=f"{header_name} must be a UUID") from None


def as_detail(order) -> OrderDetail:
    return OrderDetail.model_validate(order)


def as_event(event) -> OrderEventRead:
    return OrderEventRead.model_validate(event)


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_database()
    yield


app = FastAPI(title="OrderFlow API", version="0.1.0", lifespan=lifespan, redoc_url=None)
app.add_middleware(
    CORSMiddleware,
    allow_origins=list(settings.cors_origins),
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "X-Correlation-ID", "X-Event-ID"],
)


@app.middleware("http")
async def add_correlation_id(request: Request, call_next):
    try:
        correlation_id = safe_uuid(
            request.headers.get("X-Correlation-ID"), "X-Correlation-ID"
        )
    except HTTPException as exc:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    request.state.correlation_id = correlation_id
    response: Response = await call_next(request)
    response.headers["X-Correlation-ID"] = correlation_id
    logger.info(json.dumps({
        "event": "http_request",
        "method": request.method,
        "path": request.url.path,
        "status": response.status_code,
        "correlation_id": correlation_id,
        "environment": settings.environment,
    }, separators=(",", ":")))
    return response


@app.get("/health/live", response_model=HealthResponse)
def live() -> HealthResponse:
    return HealthResponse(status="ok")


@app.get("/health/ready", response_model=HealthResponse)
def ready(session: Session = Depends(get_session)) -> HealthResponse:
    try:
        session.execute(text("SELECT 1"))
    except Exception:
        raise HTTPException(status_code=503, detail="required dependency unavailable") from None
    return HealthResponse(status="ready")


@app.post("/api/orders", response_model=OrderDetail, status_code=202)
async def create(
    payload: OrderCreate,
    request: Request,
    session: Session = Depends(get_session),
    x_event_id: str | None = Header(default=None, alias="X-Event-ID"),
) -> OrderDetail:
    try:
        result = create_order(
            session,
            payload,
            environment=settings.environment,
            event_id=x_event_id,
            correlation_id=request.state.correlation_id,
        )
    except (EventConflictError, ValueError) as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from None
    await manager.broadcast(as_event(result.event))
    return as_detail(result.order)


@app.get("/api/orders", response_model=list[OrderSummary])
def orders(
    status: OrderStatus | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=100),
    session: Session = Depends(get_session),
) -> list[OrderSummary]:
    return [
        OrderSummary.model_validate(item)
        for item in list_orders(session, status=status, limit=limit)
    ]


@app.get("/api/orders/{order_id}", response_model=OrderDetail)
def order(order_id: str, session: Session = Depends(get_session)) -> OrderDetail:
    try:
        return as_detail(get_order(session, order_id))
    except OrderNotFoundError:
        raise HTTPException(status_code=404, detail="order not found") from None


@app.post("/api/orders/{order_id}/events", response_model=OrderDetail, status_code=202)
async def transition(
    order_id: str,
    payload: TransitionRequest,
    request: Request,
    session: Session = Depends(get_session),
    x_event_id: str | None = Header(default=None, alias="X-Event-ID"),
) -> OrderDetail:
    try:
        result = apply_transition(
            session,
            order_id=order_id,
            requested_status=payload.status,
            environment=settings.environment,
            event_id=safe_uuid(x_event_id, "X-Event-ID"),
            correlation_id=request.state.correlation_id,
        )
    except OrderNotFoundError:
        raise HTTPException(status_code=404, detail="order not found") from None
    except InvalidTransitionError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from None
    except (EventConflictError, ValueError) as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from None
    if result.created:
        await manager.broadcast(as_event(result.event))
    return as_detail(result.order)


@app.websocket("/orders")
async def order_events(websocket: WebSocket) -> None:
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        await manager.disconnect(websocket)
