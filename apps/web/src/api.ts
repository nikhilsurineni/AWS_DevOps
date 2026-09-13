import type {
  CreateOrderInput,
  OrderDetail,
  OrderStatus,
  OrderSummary,
} from "./types";

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL ?? "").replace(/\/$/, "");

export class ApiError extends Error {
  constructor(
    message: string,
    public readonly status?: number,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

const request = async <T>(path: string, init?: RequestInit): Promise<T> => {
  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${path}`, {
      ...init,
      headers: {
        Accept: "application/json",
        ...(init?.body ? { "Content-Type": "application/json" } : {}),
        ...init?.headers,
      },
    });
  } catch {
    throw new ApiError("The OrderFlow API is unavailable.");
  }

  if (!response.ok) {
    let detail = "";
    try {
      const body = (await response.json()) as { detail?: unknown };
      if (typeof body.detail === "string") detail = body.detail;
    } catch {
      // Keep the safe generic message for non-JSON or malformed responses.
    }
    throw new ApiError(detail || `Request failed with status ${response.status}.`, response.status);
  }

  try {
    return (await response.json()) as T;
  } catch {
    throw new ApiError("The API returned an unreadable response.", response.status);
  }
};

export const listOrders = async (
  status: OrderStatus | "",
  signal?: AbortSignal,
): Promise<OrderSummary[]> => {
  const query = new URLSearchParams({ limit: "100" });
  if (status) query.set("status", status);
  const orders = await request<unknown>(`/api/orders?${query.toString()}`, { signal });
  if (!Array.isArray(orders)) throw new ApiError("The API returned an invalid order list.");
  return orders as OrderSummary[];
};

export const getOrder = (id: string, signal?: AbortSignal): Promise<OrderDetail> =>
  request<OrderDetail>(`/api/orders/${encodeURIComponent(id)}`, { signal });

export const createOrder = (input: CreateOrderInput): Promise<OrderDetail> =>
  request<OrderDetail>("/api/orders", {
    method: "POST",
    body: JSON.stringify(input),
  });

export const transitionOrder = (id: string, status: OrderStatus): Promise<OrderDetail> =>
  request<OrderDetail>(`/api/orders/${encodeURIComponent(id)}/events`, {
    method: "POST",
    body: JSON.stringify({ status }),
  });

export const checkReadiness = async (signal?: AbortSignal): Promise<boolean> => {
  try {
    const response = await fetch(`${API_BASE_URL}/health/ready`, {
      headers: { Accept: "application/json" },
      signal,
    });
    return response.ok;
  } catch {
    return false;
  }
};
