from __future__ import annotations

from enum import StrEnum


class OrderStatus(StrEnum):
    CREATED = "CREATED"
    VALIDATED = "VALIDATED"
    PACKED = "PACKED"
    SHIPPED = "SHIPPED"
    DELIVERED = "DELIVERED"
    FAILED = "FAILED"


class DeliveryZone(StrEnum):
    NORTH = "NORTH"
    SOUTH = "SOUTH"
    EAST = "EAST"
    WEST = "WEST"
    CENTRAL = "CENTRAL"


NORMAL_TRANSITIONS: dict[OrderStatus, OrderStatus] = {
    OrderStatus.CREATED: OrderStatus.VALIDATED,
    OrderStatus.VALIDATED: OrderStatus.PACKED,
    OrderStatus.PACKED: OrderStatus.SHIPPED,
    OrderStatus.SHIPPED: OrderStatus.DELIVERED,
}

EVENT_TYPE_BY_STATUS: dict[OrderStatus, str] = {
    status: f"order.{status.value.lower()}" for status in OrderStatus
}


def is_allowed_transition(current: OrderStatus, requested: OrderStatus) -> bool:
    if current in {OrderStatus.DELIVERED, OrderStatus.FAILED}:
        return False
    return requested is OrderStatus.FAILED or NORMAL_TRANSITIONS.get(current) is requested
