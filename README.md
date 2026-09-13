# OrderFlow

OrderFlow is a public learning project for building and operating a near-real-time order tracking system across local development, EC2, ECS Fargate, Lambda, and Kubernetes/EKS.

The durable deliverable is reproducible code and sanitized evidence. Cloud environments are temporary and must be independently verified as removed after each lab.

## Initial milestone

- FastAPI order API with deterministic state transitions.
- PostgreSQL persistence with SQLite support for fast local tests.
- Idempotent event processing and an in-memory local event transport.
- React/TypeScript dashboard with a live event stream.
- Docker Compose development environment.
- Unit, API, frontend, and integration tests.
- Terraform, CloudFormation, Helm, and GitHub Actions foundations.

## Core commands

From Ubuntu WSL, start PostgreSQL, the API, and the web application with:

```bash
docker compose up --build
```

Open `http://127.0.0.1:8080`. The API is available at `http://127.0.0.1:8000`, including `/docs`, `/health/live`, and `/health/ready`.

```bash
docker compose ps
docker compose down
```

Use `docker compose down --volumes` when you also want to delete the synthetic local database. See the component READMEs and `docs/` contracts for focused commands. Cloud deployment is opt-in and guarded by preflight checks.

## Safety

- Use synthetic data only.
- Never commit credentials, `.env` files, Terraform state, account IDs, internal URLs, or enterprise screenshots.
- Verify the AWS account, role, Region, cost estimate, expiry tags, and teardown plan before creating resources.
- Never use a shared or Production account for a learning lab.

## Documentation

- [Architecture and contracts](docs/contracts.md)
- [Acceptance matrix](docs/acceptance-matrix.md)
- [Learning roadmap](docs/roadmap.md)
