# OrderFlow web

React and TypeScript dashboard for creating synthetic orders and observing their accepted event history.

## Local development

The Vite development server proxies REST and WebSocket traffic to the OrderFlow API on port 8000.

```bash
npm install
npm run dev
```

Open `http://localhost:5173`. Optional build-time settings:

- `VITE_API_BASE_URL`: REST origin; omit for same-origin requests.
- `VITE_WS_URL`: full WebSocket URL; omit to derive same-origin `/orders`.

## Verification

```bash
npm test
npm run build
```

## Container

The multi-stage image builds static assets and serves them as an unprivileged Nginx process on port 8080. `API_UPSTREAM` defaults to `http://api:8000` and can be overridden with a non-secret service-discovery URL.

```bash
docker build -t orderflow-web:local .
docker run --rm -p 8080:8080 -e API_UPSTREAM=http://host.docker.internal:8000 orderflow-web:local
```

The container health route is `/web-health`. Application dependency state remains authoritative at `/health/ready`.
