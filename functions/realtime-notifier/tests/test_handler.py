import importlib.util
from pathlib import Path
from typing import ClassVar

import pytest

MODULE_PATH = Path(__file__).parents[1] / "handler.py"
SPEC = importlib.util.spec_from_file_location("realtime_notifier", MODULE_PATH)
assert SPEC and SPEC.loader
handler = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(handler)


def event(**overrides):
    value = {
        "schema_version": "1.0",
        "event_id": "9b0163bc-26b3-4ec9-a59b-69e4337a3bb4",
        "order_id": "188a7d27-fecd-4934-aa68-0cab9f70f98f",
        "event_type": "order.shipped",
        "status": "SHIPPED",
        "sequence": 4,
        "occurred_at": "2026-09-13T08:00:00Z",
        "correlation_id": "86f31d41-4ff7-4490-9d91-555d62a382f5",
        "source": "orderflow-worker",
        "environment": "dev",
    }
    value.update(overrides)
    return {"detail": value}


class Table:
    def __init__(self, items):
        self.items = items
        self.deleted = []

    def scan(self, **_kwargs):
        return {"Items": self.items}

    def delete_item(self, Key):
        self.deleted.append(Key)


class Gone(Exception):
    response: ClassVar[dict[str, dict[str, str]]] = {"Error": {"Code": "GoneException"}}


class WebSocket:
    def __init__(self, gone=None, fail=None):
        self.gone = gone
        self.fail = fail
        self.posts = []

    def post_to_connection(self, ConnectionId, Data):
        if ConnectionId == self.gone:
            raise Gone()
        if ConnectionId == self.fail:
            raise OSError("transient")
        self.posts.append((ConnectionId, Data))


def test_notifies_and_removes_stale_connection():
    table = Table([{"connectionId": "live"}, {"connectionId": "stale"}])
    socket = WebSocket(gone="stale")

    result = handler.notify(event(), table, socket, max_connections=10)

    assert result == {
        "connections_considered": 2,
        "delivered": 1,
        "removed_stale": 1,
        "failed": 0,
    }
    assert table.deleted == [{"connectionId": "stale"}]
    assert b'"event_id":"9b0163bc-26b3-4ec9-a59b-69e4337a3bb4"' in socket.posts[0][1]


@pytest.mark.parametrize(
    "override",
    [
        {"schema_version": "2.0"},
        {"event_type": "order.created"},
        {"status": "UNKNOWN"},
        {"sequence": 0},
        {"occurred_at": "2026-09-13T08:00:00"},
    ],
)
def test_rejects_invalid_contract(override):
    with pytest.raises(handler.InvalidEvent):
        handler.validate_event(event(**override))


def test_transient_delivery_failure_requests_retry():
    table = Table([{"connectionId": "broken"}])
    with pytest.raises(RuntimeError, match="delivery failed"):
        handler.notify(event(), table, WebSocket(fail="broken"), max_connections=10)


def test_payload_drops_unexpected_fields():
    payload = handler.validate_event(event(secret="must-not-leak"))
    assert "secret" not in payload
