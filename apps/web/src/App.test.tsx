import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import App from "./App";
import type { OrderDetail, OrderEvent, OrderSummary } from "./types";

const acceptedEvent: OrderEvent = {
  schema_version: "1.0",
  event_id: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
  order_id: "11111111-1111-4111-8111-111111111111",
  event_type: "order.created",
  status: "CREATED",
  sequence: 1,
  occurred_at: "2026-09-14T09:00:00Z",
  correlation_id: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
  source: "order-api",
  environment: "local",
};

const summary: OrderSummary = {
  id: acceptedEvent.order_id,
  sku: "LAB-WIDGET-01",
  quantity: 2,
  delivery_zone: "NORTH",
  status: "CREATED",
  sequence: 1,
  created_at: acceptedEvent.occurred_at,
  updated_at: acceptedEvent.occurred_at,
};

const detail: OrderDetail = { ...summary, events: [acceptedEvent] };

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

class MockWebSocket {
  static instances: MockWebSocket[] = [];
  onopen: (() => void) | null = null;
  onclose: (() => void) | null = null;
  onerror: (() => void) | null = null;
  onmessage: ((event: { data: string }) => void) | null = null;

  constructor(public readonly url: string) {
    MockWebSocket.instances.push(this);
  }

  close = vi.fn();
}

const fetchMock = vi.fn<typeof fetch>();

beforeEach(() => {
  MockWebSocket.instances = [];
  vi.stubGlobal("WebSocket", MockWebSocket);
  vi.stubGlobal("fetch", fetchMock);
  fetchMock.mockImplementation(async (input, init) => {
    const url = String(input);
    if (url.includes("/health/ready")) return json({ status: "ready" });
    if (url.includes("/api/orders?")) return json([summary]);
    if (url.endsWith(`/api/orders/${summary.id}`) && init?.method !== "POST") {
      return json(detail);
    }
    throw new Error(`Unexpected request: ${url}`);
  });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("OrderFlow dashboard", () => {
  it("shows bounded orders, source freshness, and the accepted event timeline", async () => {
    render(<App />);

    expect(await screen.findByRole("button", { name: /LAB-WIDGET-01/i })).toBeInTheDocument();
    expect(await screen.findByText("Sequence 1")).toBeInTheDocument();
    expect(screen.getByText(/PostgreSQL through OrderFlow REST API/i)).toBeInTheDocument();
    expect(screen.getByText(/Showing up to 100 orders/i)).toBeInTheDocument();
  });

  it("creates a validated synthetic order with the documented request shape", async () => {
    const user = userEvent.setup();
    const created: OrderDetail = {
      ...detail,
      id: "22222222-2222-4222-8222-222222222222",
      sku: "DEMO-PART-02",
      quantity: 4,
      delivery_zone: "WEST",
      events: [{ ...acceptedEvent, order_id: "22222222-2222-4222-8222-222222222222" }],
    };
    let submittedBody: unknown;
    fetchMock.mockImplementation(async (input, init) => {
      const url = String(input);
      if (url.includes("/health/ready")) return json({ status: "ready" });
      if (url.includes("/api/orders?")) return json([summary]);
      if (url.endsWith("/api/orders") && init?.method === "POST") {
        submittedBody = JSON.parse(String(init.body));
        return json(created, 202);
      }
      if (url.includes("/api/orders/")) return json(detail);
      throw new Error(`Unexpected request: ${url}`);
    });

    render(<App />);
    await screen.findByRole("button", { name: /LAB-WIDGET-01/i });
    await user.type(screen.getByLabelText("Product SKU"), "demo-part-02");
    await user.clear(screen.getByLabelText("Quantity"));
    await user.type(screen.getByLabelText("Quantity"), "4");
    await user.selectOptions(screen.getByLabelText("Delivery zone"), "WEST");
    await user.click(screen.getByRole("button", { name: "Create synthetic order" }));

    expect(await screen.findByText(/Order DEMO-PART-02 was accepted/i)).toBeInTheDocument();
    expect(submittedBody).toEqual({
      sku: "DEMO-PART-02",
      quantity: 4,
      delivery_zone: "WEST",
    });
  });

  it("reports source unavailability instead of showing a healthy empty state", async () => {
    fetchMock.mockImplementation(async (input) => {
      if (String(input).includes("/health/ready")) return json({ status: "ready" });
      throw new TypeError("Network unavailable");
    });

    render(<App />);

    expect(await screen.findByText("Order data unavailable")).toBeInTheDocument();
    expect(screen.getByText("The OrderFlow API is unavailable.")).toBeInTheDocument();
    expect(screen.getByText("API Unavailable")).toBeInTheDocument();
  });

  it("labels a disconnected stream as REST fallback", async () => {
    render(<App />);
    await screen.findByRole("button", { name: /LAB-WIDGET-01/i });
    const socket = MockWebSocket.instances[0];
    socket.onopen?.();
    expect(await screen.findByText("Stream Live")).toBeInTheDocument();

    socket.onclose?.();
    await waitFor(() => expect(screen.getByText("Stream REST fallback")).toBeInTheDocument());
  });
});
