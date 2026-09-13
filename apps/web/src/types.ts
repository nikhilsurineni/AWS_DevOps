export const ORDER_STATUSES = [
  "CREATED",
  "VALIDATED",
  "PACKED",
  "SHIPPED",
  "DELIVERED",
  "FAILED",
] as const;

export type OrderStatus = (typeof ORDER_STATUSES)[number];

export const DELIVERY_ZONES = ["NORTH", "SOUTH", "EAST", "WEST", "CENTRAL"] as const;
export type DeliveryZone = (typeof DELIVERY_ZONES)[number];

export type OrderEnvironment = "local" | "personal-learning" | "enterprise-sandbox";

export interface OrderSummary {
  id: string;
  sku: string;
  quantity: number;
  delivery_zone: DeliveryZone;
  status: OrderStatus;
  sequence: number;
  created_at: string;
  updated_at: string;
}

export interface OrderEvent {
  schema_version: "1.0";
  event_id: string;
  order_id: string;
  event_type: string;
  status: OrderStatus;
  sequence: number;
  occurred_at: string;
  correlation_id: string;
  source: string;
  environment: OrderEnvironment;
}

export interface OrderDetail extends OrderSummary {
  events: OrderEvent[];
}

export interface CreateOrderInput {
  sku: string;
  quantity: number;
  delivery_zone: DeliveryZone;
}

export type ConnectionState = "connecting" | "live" | "fallback" | "unavailable";

export const nextStatuses = (status: OrderStatus): OrderStatus[] => {
  if (status === "DELIVERED" || status === "FAILED") return [];
  const next: Partial<Record<OrderStatus, OrderStatus>> = {
    CREATED: "VALIDATED",
    VALIDATED: "PACKED",
    PACKED: "SHIPPED",
    SHIPPED: "DELIVERED",
  };
  return [next[status]!, "FAILED"];
};
