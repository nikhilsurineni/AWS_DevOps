from __future__ import annotations

from datetime import UTC, datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_serializer

from .domain import DeliveryZone, OrderStatus


class OrderCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    sku: str = Field(min_length=3, max_length=32, pattern=r"^[A-Za-z0-9][A-Za-z0-9-]*$")
    quantity: int = Field(ge=1, le=100)
    delivery_zone: DeliveryZone


class TransitionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    status: OrderStatus


class OrderEventRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    schema_version: Literal["1.0"]
    event_id: str
    order_id: str
    event_type: str
    status: OrderStatus
    sequence: int
    occurred_at: datetime
    correlation_id: str
    source: str
    environment: str

    @field_serializer("occurred_at")
    def serialize_occurred_at(self, value: datetime) -> str:
        normalized = value if value.tzinfo is not None else value.replace(tzinfo=UTC)
        return normalized.astimezone(UTC).isoformat().replace("+00:00", "Z")


class OrderSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    sku: str
    quantity: int
    delivery_zone: DeliveryZone
    status: OrderStatus
    sequence: int
    created_at: datetime
    updated_at: datetime

    @field_serializer("created_at", "updated_at")
    def serialize_order_time(self, value: datetime) -> str:
        normalized = value if value.tzinfo is not None else value.replace(tzinfo=UTC)
        return normalized.astimezone(UTC).isoformat().replace("+00:00", "Z")


class OrderDetail(OrderSummary):
    events: list[OrderEventRead]


class HealthResponse(BaseModel):
    status: Literal["ok", "ready"]
