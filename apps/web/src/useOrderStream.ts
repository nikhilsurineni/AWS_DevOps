import { useEffect, useState } from "react";
import type { ConnectionState, OrderEvent } from "./types";

const websocketUrl = (): string => {
  const configured = import.meta.env.VITE_WS_URL as string | undefined;
  if (configured) return configured;
  const scheme = window.location.protocol === "https:" ? "wss:" : "ws:";
  return `${scheme}//${window.location.host}/orders`;
};

const isOrderEvent = (value: unknown): value is OrderEvent => {
  if (!value || typeof value !== "object") return false;
  const event = value as Partial<OrderEvent>;
  return (
    event.schema_version === "1.0" &&
    typeof event.event_id === "string" &&
    typeof event.order_id === "string" &&
    typeof event.status === "string" &&
    typeof event.sequence === "number"
  );
};

export const useOrderStream = (onEvent: (event: OrderEvent) => void): ConnectionState => {
  const [state, setState] = useState<ConnectionState>("connecting");

  useEffect(() => {
    if (typeof WebSocket === "undefined") {
      setState("unavailable");
      return;
    }

    let socket: WebSocket | undefined;
    let retryTimer: number | undefined;
    let mounted = true;
    let attempt = 0;

    const connect = () => {
      if (!mounted) return;
      setState(attempt === 0 ? "connecting" : "fallback");

      try {
        socket = new WebSocket(websocketUrl());
      } catch {
        setState("unavailable");
        return;
      }

      socket.onopen = () => {
        attempt = 0;
        setState("live");
      };

      socket.onmessage = (message) => {
        try {
          const event: unknown = JSON.parse(String(message.data));
          if (isOrderEvent(event)) onEvent(event);
        } catch {
          // Ignore malformed stream messages; the REST source remains authoritative.
        }
      };

      socket.onerror = () => socket?.close();
      socket.onclose = () => {
        if (!mounted) return;
        setState("fallback");
        const delay = Math.min(1000 * 2 ** attempt, 10_000);
        attempt += 1;
        retryTimer = window.setTimeout(connect, delay);
      };
    };

    connect();

    return () => {
      mounted = false;
      if (retryTimer !== undefined) window.clearTimeout(retryTimer);
      socket?.close();
    };
  }, [onEvent]);

  return state;
};
