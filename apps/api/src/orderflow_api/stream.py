from __future__ import annotations

import asyncio
from dataclasses import dataclass

from fastapi import WebSocket

from .domain import OrderStatus
from .schemas import OrderEventRead


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: set[WebSocket] = set()
        self._lock = asyncio.Lock()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections.add(websocket)

    async def disconnect(self, websocket: WebSocket) -> None:
        async with self._lock:
            self._connections.discard(websocket)

    async def broadcast(self, event: OrderEventRead) -> None:
        payload = event.model_dump(mode="json")
        async with self._lock:
            connections = tuple(self._connections)
        stale: list[WebSocket] = []
        for connection in connections:
            try:
                await connection.send_json(payload)
            except Exception:
                stale.append(connection)
        if stale:
            async with self._lock:
                for connection in stale:
                    self._connections.discard(connection)


@dataclass
class TransitionJob:
    order_id: str
    status: OrderStatus
    event_id: str
    correlation_id: str
    result: asyncio.Future
