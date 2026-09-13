from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import delete

from orderflow_api.database import Base, SessionLocal, engine
from orderflow_api.main import app
from orderflow_api.models import Order, OrderEvent


def reset_database() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as session:
        session.execute(delete(OrderEvent))
        session.execute(delete(Order))
        session.commit()


def test_order_lifecycle_idempotency_and_websocket() -> None:
    reset_database()
    correlation_id = "11111111-1111-4111-8111-111111111111"
    create_event_id = "22222222-2222-4222-8222-222222222222"
    transition_event_id = "33333333-3333-4333-8333-333333333333"

    with TestClient(app) as client:
        assert client.get("/health/live").json() == {"status": "ok"}
        assert client.get("/health/ready").json() == {"status": "ready"}

        created = client.post(
            "/api/orders",
            headers={
                "X-Correlation-ID": correlation_id,
                "X-Event-ID": create_event_id,
            },
            json={"sku": "lab-widget-01", "quantity": 2, "delivery_zone": "NORTH"},
        )
        assert created.status_code == 202
        assert created.headers["X-Correlation-ID"] == correlation_id
        order = created.json()
        assert order["sku"] == "LAB-WIDGET-01"
        assert order["status"] == "CREATED"
        assert order["sequence"] == 1
        assert order["created_at"].endswith("Z")
        assert order["events"][0]["occurred_at"].endswith("Z")

        listed = client.get("/api/orders", params={"status": "CREATED", "limit": 100})
        assert listed.status_code == 200
        assert [item["id"] for item in listed.json()] == [order["id"]]

        with client.websocket_connect("/orders") as websocket:
            changed = client.post(
                f"/api/orders/{order['id']}/events",
                headers={"X-Event-ID": transition_event_id},
                json={"status": "VALIDATED"},
            )
            event = websocket.receive_json()

        assert changed.status_code == 202
        changed_order = changed.json()
        assert changed_order["status"] == "VALIDATED"
        assert changed_order["sequence"] == 2
        assert event["event_id"] == transition_event_id
        assert event["status"] == "VALIDATED"
        assert event["source"] == "order-worker"

        duplicate = client.post(
            f"/api/orders/{order['id']}/events",
            headers={"X-Event-ID": transition_event_id},
            json={"status": "VALIDATED"},
        )
        assert duplicate.status_code == 202
        assert duplicate.json()["sequence"] == 2
        assert len(duplicate.json()["events"]) == 2

        invalid = client.post(
            f"/api/orders/{order['id']}/events",
            json={"status": "SHIPPED"},
        )
        assert invalid.status_code == 409
        assert client.get("/api/orders/not-found").status_code == 404


def test_validation_fails_closed() -> None:
    reset_database()
    with TestClient(app) as client:
        bad_order = client.post(
            "/api/orders",
            json={"sku": "real customer", "quantity": 0, "delivery_zone": "UNKNOWN"},
        )
        assert bad_order.status_code == 422

        bad_correlation = client.get(
            "/health/live", headers={"X-Correlation-ID": "not-a-uuid"}
        )
        assert bad_correlation.status_code == 400
