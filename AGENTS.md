# OrderFlow Project Operating Contract

- Purpose: public, synthetic-data AWS and DevOps learning portfolio.
- Primary stack: FastAPI, React/TypeScript, PostgreSQL, Docker, Terraform, GitHub Actions.
- Supported environments: local, personal-learning, and a separately verified enterprise sandbox.
- Default personal Region: `us-east-1`; never assume the enterprise Region, account, or role.
- Public repository boundary: no corporate account IDs, internal URLs, screenshots, policies, names, data, or credentials.
- Secret boundary: local environment or approved workload identity only; never Git, images, logs, screenshots, Terraform variables, or browser payloads.
- Data boundary: synthetic order data only; no personal, payment, customer, or corporate information.
- Cloud mutation gate: verify exact account, role, Region, environment, estimate, tags, and teardown before applying.
- Production and shared accounts are out of scope. Enterprise activity is restricted to the dedicated sandbox.
- Required resource tags: `Project`, `Environment`, `Owner`, `ManagedBy`, and `ExpiresOn`.
- Routine labs must not create NAT Gateways. EKS and load-balancer labs are time-boxed and destroyed in the same session.
- Use immutable commit-SHA image tags and deploy the same digest across runtimes.
- Update architecture, tests, evidence, and rollback notes when a trust boundary or deployment topology changes.
