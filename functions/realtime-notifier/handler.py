"""EventBridge-to-WebSocket notifier for synthetic OrderFlow events."""

from __future__ import annotations

import json
import logging
import os
from datetime import datetime
from typing import Any
from uuid import UUID

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.INFO)

ALLOWED_STATUSES = {
    "CREATED",
    "VALIDATED",
    "PACKED",
    "SHIPPED",
    "DELIVERED",
    "FAILED",
}
REQUIRED_FIELDS = {
    "schema_version",
    "event_id",
    "order_id",
    "event_type",
    "status",
    "sequence",
    "occurred_at",
    "correlation_id",
    "source",
    "environment",
}


class InvalidEvent(ValueError):
    """Raised when an incoming event does not satisfy the public contract."""


def _uuid(value: Any, field: str) -> str:
    try:
        return str(UUID(str(value)))
    except (ValueError, TypeError, AttributeError) as exc:
        raise InvalidEvent(f"{field} must be a UUID") from exc


def _timestamp(value: Any) -> str:
    if not isinstance(value, str):
        raise InvalidEvent("occurred_at must be an ISO-8601 string")
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise InvalidEvent("occurred_at must be a valid ISO-8601 timestamp") from exc
    if parsed.tzinfo is None:
        raise InvalidEvent("occurred_at must include a timezone")
    return value


def validate_event(raw_event: dict[str, Any]) -> dict[str, Any]:
    """Return a bounded event envelope or fail closed."""
    detail = raw_event.get("detail", raw_event)
    if isinstance(detail, str):
        try:
            detail = json.loads(detail)
        except json.JSONDecodeError as exc:
            raise InvalidEvent("EventBridge detail is not valid JSON") from exc
    if not isinstance(detail, dict):
        raise InvalidEvent("event detail must be an object")

    missing = REQUIRED_FIELDS - detail.keys()
    if missing:
        raise InvalidEvent(f"missing required fields: {', '.join(sorted(missing))}")

    status = detail["status"]
    if status not in ALLOWED_STATUSES:
        raise InvalidEvent("status is not an allowed OrderFlow state")
    expected_type = f"order.{str(status).lower()}"
    if detail["event_type"] != expected_type:
        raise InvalidEvent(f"event_type must be {expected_type}")
    if detail["schema_version"] != "1.0":
        raise InvalidEvent("unsupported schema_version")
    sequence = detail["sequence"]
    if not isinstance(sequence, int) or isinstance(sequence, bool) or sequence < 1:
        raise InvalidEvent("sequence must be a positive integer")
    if not isinstance(detail["source"], str) or not detail["source"].strip():
        raise InvalidEvent("source must be a non-empty string")
    if not isinstance(detail["environment"], str) or not detail["environment"].strip():
        raise InvalidEvent("environment must be a non-empty string")

    # Rebuild the payload from allowlisted fields so EventBridge metadata and
    # accidental additional fields are never pushed to browsers.
    return {
        "schema_version": "1.0",
        "event_id": _uuid(detail["event_id"], "event_id"),
        "order_id": _uuid(detail["order_id"], "order_id"),
        "event_type": detail["event_type"],
        "status": status,
        "sequence": detail["sequence"],
        "occurred_at": _timestamp(detail["occurred_at"]),
        "correlation_id": _uuid(detail["correlation_id"], "correlation_id"),
        "source": detail["source"].strip(),
        "environment": detail["environment"].strip(),
    }


def _error_code(exc: Exception) -> str:
    response = getattr(exc, "response", {})
    if isinstance(response, dict):
        error = response.get("Error", {})
        if isinstance(error, dict):
            return str(error.get("Code", ""))
    return ""


def notify(
    event: dict[str, Any],
    table: Any,
    websocket_client: Any,
    max_connections: int,
) -> dict[str, int]:
    """Push one validated event to a bounded connection set."""
    payload = validate_event(event)
    body = json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    connections: list[str] = []
    scan_args: dict[str, Any] = {
        "ProjectionExpression": "connectionId",
        "Limit": max_connections,
    }

    while len(connections) < max_connections:
        page = table.scan(**scan_args)
        for item in page.get("Items", []):
            connection_id = item.get("connectionId")
            if isinstance(connection_id, str) and connection_id:
                connections.append(connection_id)
                if len(connections) == max_connections:
                    break
        last_key = page.get("LastEvaluatedKey")
        if not last_key or len(connections) == max_connections:
            break
        scan_args["ExclusiveStartKey"] = last_key
        scan_args["Limit"] = max_connections - len(connections)

    delivered = 0
    removed = 0
    failures = 0
    for connection_id in connections:
        try:
            websocket_client.post_to_connection(ConnectionId=connection_id, Data=body)
            delivered += 1
        except Exception as exc:  # noqa: BLE001 - AWS service exceptions are generated at runtime.
            if _error_code(exc) in {"GoneException", "410"}:
                table.delete_item(Key={"connectionId": connection_id})
                removed += 1
            else:
                failures += 1
                LOGGER.warning(
                    json.dumps(
                        {
                            "event": "websocket_delivery_failed",
                            "event_id": payload["event_id"],
                            "error_category": type(exc).__name__,
                        }
                    )
                )

    result = {
        "connections_considered": len(connections),
        "delivered": delivered,
        "removed_stale": removed,
        "failed": failures,
    }
    LOGGER.info(json.dumps({"event": "notification_complete", **result}))
    if failures:
        # EventBridge retries. Clients must deduplicate by event_id.
        raise RuntimeError(f"delivery failed for {failures} connection(s)")
    return result


def lambda_handler(event: dict[str, Any], _context: Any) -> dict[str, int]:
    table_name = os.environ.get("CONNECTIONS_TABLE", "")
    endpoint = os.environ.get("WEBSOCKET_MANAGEMENT_ENDPOINT", "")
    try:
        max_connections = int(os.environ.get("MAX_CONNECTIONS", "1000"))
    except ValueError as exc:
        raise RuntimeError("MAX_CONNECTIONS must be an integer") from exc

    if not table_name or not endpoint.startswith("https://"):
        raise RuntimeError("required notifier configuration is missing")
    if not 1 <= max_connections <= 10000:
        raise RuntimeError("MAX_CONNECTIONS must be between 1 and 10000")

    import boto3  # Lambda runtime dependency; kept lazy for lightweight tests.

    table = boto3.resource("dynamodb").Table(table_name)
    websocket_client = boto3.client("apigatewaymanagementapi", endpoint_url=endpoint)
    return notify(event, table, websocket_client, max_connections)
