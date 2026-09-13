from __future__ import annotations

from dataclasses import dataclass
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .domain import EVENT_TYPE_BY_STATUS, OrderStatus, is_allowed_transition
from .models import Order, OrderEvent, utc_now
from .schemas import OrderCreate


class OrderNotFoundError(LookupError):
    pass


class InvalidTransitionError(ValueError):
    pass


class EventConflictError(ValueError):
    pass


@dataclass(frozen=True)
class TransitionResult:
    order: Order
    event: OrderEvent
    created: bool


def _uuid_or_new(value: str | None) -> str:
    if value is None:
        return str(uuid4())
    return str(UUID(value))


def get_order(session: Session, order_id: str) -> Order:
    order = session.scalar(select(Order).where(Order.id == order_id))
    if order is None:
        raise OrderNotFoundError(order_id)
    return order


def list_orders(
    session: Session, *, status: OrderStatus | None = None, limit: int = 100
) -> list[Order]:
    statement = select(Order).order_by(Order.updated_at.desc()).limit(limit)
    if status is not None:
        statement = statement.where(Order.status == status.value)
    return list(session.scalars(statement).all())


def create_order(
    session: Session,
    payload: OrderCreate,
    *,
    environment: str,
    event_id: str | None = None,
    correlation_id: str | None = None,
) -> TransitionResult:
    event_key = _uuid_or_new(event_id)
    correlation_key = _uuid_or_new(correlation_id)
    existing = session.get(OrderEvent, event_key)
    if existing is not None:
        raise EventConflictError("event_id already belongs to another accepted request")

    now = utc_now()
    order = Order(
        id=str(uuid4()),
        sku=payload.sku.upper(),
        quantity=payload.quantity,
        delivery_zone=payload.delivery_zone.value,
        status=OrderStatus.CREATED.value,
        sequence=1,
        environment=environment,
        created_at=now,
        updated_at=now,
    )
    event = OrderEvent(
        schema_version="1.0",
        event_id=event_key,
        order_id=order.id,
        event_type=EVENT_TYPE_BY_STATUS[OrderStatus.CREATED],
        status=OrderStatus.CREATED.value,
        sequence=1,
        occurred_at=now,
        correlation_id=correlation_key,
        source="order-api",
        environment=environment,
    )
    order.events.append(event)
    session.add(order)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise EventConflictError("the order event conflicts with accepted state") from None
    session.refresh(order)
    return TransitionResult(order=order, event=event, created=True)


def apply_transition(
    session: Session,
    *,
    order_id: str,
    requested_status: OrderStatus,
    environment: str,
    event_id: str,
    correlation_id: str,
) -> TransitionResult:
    event_key = _uuid_or_new(event_id)
    correlation_key = _uuid_or_new(correlation_id)
    existing = session.get(OrderEvent, event_key)
    if existing is not None:
        if existing.order_id != order_id or existing.status != requested_status.value:
            raise EventConflictError("event_id was already used for a different transition")
        return TransitionResult(order=get_order(session, order_id), event=existing, created=False)

    order = get_order(session, order_id)
    current = OrderStatus(order.status)
    if order.environment != environment:
        raise EventConflictError("cross-environment transition rejected")
    if not is_allowed_transition(current, requested_status):
        raise InvalidTransitionError(
            f"transition from {current.value} to {requested_status.value} is not allowed"
        )

    now = utc_now()
    next_sequence = order.sequence + 1
    event = OrderEvent(
        schema_version="1.0",
        event_id=event_key,
        order_id=order.id,
        event_type=EVENT_TYPE_BY_STATUS[requested_status],
        status=requested_status.value,
        sequence=next_sequence,
        occurred_at=now,
        correlation_id=correlation_key,
        source="order-worker",
        environment=environment,
    )
    order.status = requested_status.value
    order.sequence = next_sequence
    order.updated_at = now
    order.events.append(event)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        existing = session.get(OrderEvent, event_key)
        if (
            existing is not None
            and existing.order_id == order_id
            and existing.status == requested_status.value
        ):
            return TransitionResult(
                order=get_order(session, order_id), event=existing, created=False
            )
        raise EventConflictError("the event conflicts with accepted order state") from None
    session.refresh(order)
    return TransitionResult(order=order, event=event, created=True)
