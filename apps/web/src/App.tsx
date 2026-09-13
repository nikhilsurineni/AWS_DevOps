import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import {
  ApiError,
  checkReadiness,
  createOrder,
  getOrder,
  listOrders,
  transitionOrder,
} from "./api";
import {
  DELIVERY_ZONES,
  ORDER_STATUSES,
  nextStatuses,
  type CreateOrderInput,
  type OrderDetail,
  type OrderStatus,
  type OrderSummary,
} from "./types";
import { useOrderStream } from "./useOrderStream";

const EMPTY_FORM: CreateOrderInput = {
  sku: "",
  quantity: 1,
  delivery_zone: "NORTH",
};

const timeFormatter = new Intl.DateTimeFormat(undefined, {
  dateStyle: "medium",
  timeStyle: "short",
});

const formatTime = (value: string): string => {
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? "Unknown time" : timeFormatter.format(date);
};

const safeError = (error: unknown): string =>
  error instanceof ApiError ? error.message : "The request could not be completed.";

const statusTone = (status: OrderStatus): string => status.toLowerCase();

function CreateOrderForm({
  onCreated,
}: {
  onCreated: (order: OrderDetail) => void;
}) {
  const [form, setForm] = useState<CreateOrderInput>(EMPTY_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    const sku = form.sku.trim().toUpperCase();
    if (!/^[A-Z0-9-]{3,32}$/.test(sku)) {
      setError("Use 3–32 letters, numbers, or hyphens for the synthetic SKU.");
      return;
    }
    if (!Number.isInteger(form.quantity) || form.quantity < 1 || form.quantity > 100) {
      setError("Quantity must be a whole number from 1 to 100.");
      return;
    }

    setSubmitting(true);
    try {
      const order = await createOrder({ ...form, sku });
      setForm(EMPTY_FORM);
      onCreated(order);
    } catch (requestError) {
      setError(safeError(requestError));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section className="card create-card" aria-labelledby="create-title">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Synthetic workload</p>
          <h2 id="create-title">Create an order</h2>
        </div>
        <span className="privacy-label">No customer data</span>
      </div>
      <form onSubmit={submit} noValidate>
        <div className="field">
          <label htmlFor="sku">Product SKU</label>
          <input
            id="sku"
            name="sku"
            value={form.sku}
            onChange={(event) => setForm({ ...form, sku: event.target.value })}
            placeholder="LAB-WIDGET-01"
            autoComplete="off"
            maxLength={32}
            required
          />
          <span className="field-hint">Synthetic identifier only</span>
        </div>
        <div className="form-row">
          <div className="field">
            <label htmlFor="quantity">Quantity</label>
            <input
              id="quantity"
              name="quantity"
              type="number"
              value={form.quantity}
              onChange={(event) =>
                setForm({ ...form, quantity: Number(event.target.value) })
              }
              min={1}
              max={100}
              step={1}
              required
            />
          </div>
          <div className="field">
            <label htmlFor="delivery-zone">Delivery zone</label>
            <select
              id="delivery-zone"
              name="delivery_zone"
              value={form.delivery_zone}
              onChange={(event) =>
                setForm({
                  ...form,
                  delivery_zone: event.target.value as CreateOrderInput["delivery_zone"],
                })
              }
            >
              {DELIVERY_ZONES.map((zone) => (
                <option key={zone} value={zone}>
                  {zone.charAt(0) + zone.slice(1).toLowerCase()}
                </option>
              ))}
            </select>
          </div>
        </div>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <button className="primary-button" type="submit" disabled={submitting}>
          {submitting ? "Creating…" : "Create synthetic order"}
        </button>
      </form>
    </section>
  );
}

function OrderList({
  orders,
  selectedId,
  filter,
  loading,
  error,
  onSelect,
  onFilter,
  onRetry,
}: {
  orders: OrderSummary[];
  selectedId: string | null;
  filter: OrderStatus | "";
  loading: boolean;
  error: string;
  onSelect: (id: string) => void;
  onFilter: (status: OrderStatus | "") => void;
  onRetry: () => void;
}) {
  return (
    <section className="card orders-card" aria-labelledby="orders-title">
      <div className="section-heading">
        <div>
          <p className="eyebrow">PostgreSQL authority</p>
          <h2 id="orders-title">Recent orders</h2>
        </div>
        <div className="filter">
          <label htmlFor="status-filter">Status</label>
          <select
            id="status-filter"
            value={filter}
            onChange={(event) => onFilter(event.target.value as OrderStatus | "")}
          >
            <option value="">All</option>
            {ORDER_STATUSES.map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
        </div>
      </div>

      {error && (
        <div className="state-banner danger" role="alert">
          <div>
            <strong>Order data unavailable</strong>
            <span>{error}</span>
          </div>
          <button className="text-button" type="button" onClick={onRetry}>
            Retry
          </button>
        </div>
      )}

      {loading && orders.length === 0 ? (
        <div className="empty-state" role="status">
          <span className="loading-dot" aria-hidden="true" />
          Loading the bounded order list…
        </div>
      ) : orders.length === 0 && !error ? (
        <div className="empty-state">
          <strong>No matching orders</strong>
          <span>Create a synthetic order or change the status filter.</span>
        </div>
      ) : (
        <div className="order-list" aria-label="Orders">
          {orders.map((order) => (
            <button
              className={`order-row ${order.id === selectedId ? "selected" : ""}`}
              type="button"
              key={order.id}
              onClick={() => onSelect(order.id)}
              aria-pressed={order.id === selectedId}
            >
              <span className="order-row-main">
                <strong>{order.sku}</strong>
                <span>#{order.id.slice(0, 8)} · {order.delivery_zone}</span>
              </span>
              <span className="order-row-meta">
                <span className={`status-badge ${statusTone(order.status)}`}>
                  {order.status}
                </span>
                <span>{formatTime(order.updated_at)}</span>
              </span>
            </button>
          ))}
        </div>
      )}
      <p className="bounded-note">Showing up to 100 orders from the selected status.</p>
    </section>
  );
}

function OrderDetails({
  order,
  loading,
  error,
  onTransition,
}: {
  order: OrderDetail | null;
  loading: boolean;
  error: string;
  onTransition: (status: OrderStatus) => Promise<void>;
}) {
  const [transitioning, setTransitioning] = useState<OrderStatus | null>(null);
  const [transitionError, setTransitionError] = useState("");

  const runTransition = async (status: OrderStatus) => {
    setTransitioning(status);
    setTransitionError("");
    try {
      await onTransition(status);
    } catch (requestError) {
      setTransitionError(safeError(requestError));
    } finally {
      setTransitioning(null);
    }
  };

  return (
    <section className="card details-card" aria-labelledby="details-title">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Accepted event history</p>
          <h2 id="details-title">Order timeline</h2>
        </div>
        {order && (
          <span className={`status-badge ${statusTone(order.status)}`}>
            {order.status}
          </span>
        )}
      </div>

      {loading && !order ? (
        <div className="empty-state" role="status">Loading order details…</div>
      ) : error ? (
        <div className="state-banner danger" role="alert">
          <div>
            <strong>Timeline unavailable</strong>
            <span>{error}</span>
          </div>
        </div>
      ) : !order ? (
        <div className="empty-state">
          <strong>Select an order</strong>
          <span>Its accepted state changes will appear here.</span>
        </div>
      ) : (
        <>
          <dl className="order-facts">
            <div><dt>SKU</dt><dd>{order.sku}</dd></div>
            <div><dt>Quantity</dt><dd>{order.quantity}</dd></div>
            <div><dt>Zone</dt><dd>{order.delivery_zone}</dd></div>
            <div><dt>Sequence</dt><dd>{order.sequence}</dd></div>
          </dl>

          {nextStatuses(order.status).length > 0 && (
            <div className="transition-panel">
              <div>
                <strong>Simulate next event</strong>
                <span>Invalid and out-of-order transitions are rejected by the API.</span>
              </div>
              <div className="button-group">
                {nextStatuses(order.status).map((status) => (
                  <button
                    className={status === "FAILED" ? "danger-button" : "secondary-button"}
                    type="button"
                    key={status}
                    disabled={transitioning !== null}
                    onClick={() => void runTransition(status)}
                  >
                    {transitioning === status ? "Applying…" : status}
                  </button>
                ))}
              </div>
            </div>
          )}
          {transitionError && <p className="form-error" role="alert">{transitionError}</p>}

          <ol className="timeline">
            {[...order.events]
              .sort((a, b) => b.sequence - a.sequence)
              .map((event) => (
                <li key={event.event_id}>
                  <span className={`timeline-marker ${statusTone(event.status)}`} aria-hidden="true" />
                  <div>
                    <div className="timeline-title">
                      <strong>{event.status}</strong>
                      <span>Sequence {event.sequence}</span>
                    </div>
                    <time dateTime={event.occurred_at}>{formatTime(event.occurred_at)}</time>
                    <span className="event-source">{event.source} · {event.environment}</span>
                  </div>
                </li>
              ))}
          </ol>
        </>
      )}
    </section>
  );
}

export default function App() {
  const [orders, setOrders] = useState<OrderSummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selectedOrder, setSelectedOrder] = useState<OrderDetail | null>(null);
  const [filter, setFilter] = useState<OrderStatus | "">("");
  const [listLoading, setListLoading] = useState(true);
  const [detailLoading, setDetailLoading] = useState(false);
  const [listError, setListError] = useState("");
  const [detailError, setDetailError] = useState("");
  const [apiReady, setApiReady] = useState<boolean | null>(null);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<Date | null>(null);
  const [refreshToken, setRefreshToken] = useState(0);
  const [notice, setNotice] = useState("");

  const streamState = useOrderStream(
    useCallback(() => setRefreshToken((value) => value + 1), []),
  );

  useEffect(() => {
    const controller = new AbortController();
    setListLoading(true);
    void Promise.all([
      listOrders(filter, controller.signal),
      checkReadiness(controller.signal),
    ])
      .then(([nextOrders, ready]) => {
        setOrders(nextOrders);
        setApiReady(ready);
        setListError("");
        setLastUpdatedAt(new Date());
        setSelectedId((current) => {
          if (current && nextOrders.some((order) => order.id === current)) return current;
          return nextOrders[0]?.id ?? null;
        });
      })
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        setListError(safeError(error));
        setApiReady(false);
      })
      .finally(() => {
        if (!controller.signal.aborted) setListLoading(false);
      });
    return () => controller.abort();
  }, [filter, refreshToken]);

  useEffect(() => {
    if (streamState === "live") return;
    const interval = window.setInterval(
      () => setRefreshToken((value) => value + 1),
      15_000,
    );
    return () => window.clearInterval(interval);
  }, [streamState]);

  useEffect(() => {
    if (!selectedId) {
      setSelectedOrder(null);
      setDetailError("");
      return;
    }
    const controller = new AbortController();
    setDetailLoading(true);
    void getOrder(selectedId, controller.signal)
      .then((order) => {
        setSelectedOrder(order);
        setDetailError("");
      })
      .catch((error: unknown) => {
        if (!controller.signal.aborted) setDetailError(safeError(error));
      })
      .finally(() => {
        if (!controller.signal.aborted) setDetailLoading(false);
      });
    return () => controller.abort();
  }, [selectedId, refreshToken]);

  const counts = useMemo(
    () => ({
      active: orders.filter((order) => !["DELIVERED", "FAILED"].includes(order.status)).length,
      delivered: orders.filter((order) => order.status === "DELIVERED").length,
      failed: orders.filter((order) => order.status === "FAILED").length,
    }),
    [orders],
  );

  const created = (order: OrderDetail) => {
    setSelectedId(order.id);
    setSelectedOrder(order);
    setNotice(`Order ${order.sku} was accepted for processing.`);
    setRefreshToken((value) => value + 1);
  };

  const transition = async (status: OrderStatus) => {
    if (!selectedId) return;
    const order = await transitionOrder(selectedId, status);
    setSelectedOrder(order);
    setNotice(`Order ${order.sku} moved to ${order.status}.`);
    setRefreshToken((value) => value + 1);
  };

  const dataState = apiReady === null ? "Checking" : apiReady ? "Available" : "Unavailable";
  const streamLabel = {
    connecting: "Connecting",
    live: "Live",
    fallback: "REST fallback",
    unavailable: "Unavailable",
  }[streamState];

  return (
    <div className="app-shell">
      <header className="topbar">
        <a className="brand" href="#main">
          <span className="brand-mark" aria-hidden="true">OF</span>
          <span><strong>OrderFlow</strong><small>AWS + DevOps learning lab</small></span>
        </a>
        <div className="system-summary" aria-label="System status">
          <div><span className={`health-dot ${apiReady ? "healthy" : ""}`} /><span>API {dataState}</span></div>
          <div><span className={`health-dot ${streamState === "live" ? "healthy" : "warning"}`} /><span>Stream {streamLabel}</span></div>
        </div>
      </header>

      <main id="main">
        <section className="hero" aria-labelledby="page-title">
          <div>
            <p className="eyebrow">Local environment · Synthetic data</p>
            <h1 id="page-title">Follow every order event, as it happens.</h1>
            <p>
              Create a safe test order, observe its accepted state transitions, and see
              how REST and WebSocket delivery behave when dependencies change.
            </p>
          </div>
          <button className="refresh-button" type="button" onClick={() => setRefreshToken((value) => value + 1)}>
            Refresh data
          </button>
        </section>

        {notice && (
          <div className="toast" role="status">
            <span>{notice}</span>
            <button type="button" onClick={() => setNotice("")} aria-label="Dismiss notification">×</button>
          </div>
        )}

        <section className="metrics" aria-label="Order summary">
          <article><span>Visible orders</span><strong>{orders.length}</strong><small>Bounded REST view</small></article>
          <article><span>Active</span><strong>{counts.active}</strong><small>Awaiting delivery</small></article>
          <article><span>Delivered</span><strong>{counts.delivered}</strong><small>Terminal success</small></article>
          <article className={counts.failed ? "metric-alert" : ""}><span>Failed</span><strong>{counts.failed}</strong><small>Needs review</small></article>
        </section>

        <section className="freshness-bar" aria-label="Data freshness">
          <span><strong>Source:</strong> PostgreSQL through OrderFlow REST API</span>
          <span>
            <strong>Last successful refresh:</strong>{" "}
            {lastUpdatedAt ? timeFormatter.format(lastUpdatedAt) : "No successful refresh"}
          </span>
          <span><strong>Realtime:</strong> {streamLabel}</span>
        </section>

        <div className="dashboard-grid">
          <CreateOrderForm onCreated={created} />
          <OrderList
            orders={orders}
            selectedId={selectedId}
            filter={filter}
            loading={listLoading}
            error={listError}
            onSelect={setSelectedId}
            onFilter={setFilter}
            onRetry={() => setRefreshToken((value) => value + 1)}
          />
          <OrderDetails
            order={selectedOrder}
            loading={detailLoading}
            error={detailError}
            onTransition={transition}
          />
        </div>
      </main>

      <footer>
        OrderFlow uses synthetic data only. Queue and log state support troubleshooting;
        PostgreSQL remains authoritative for order history.
      </footer>
    </div>
  );
}
