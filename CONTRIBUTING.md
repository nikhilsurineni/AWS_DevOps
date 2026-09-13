# Contributing

OrderFlow is a learning portfolio, but changes follow production-style review discipline.

## Workflow

1. Create a focused issue describing the behavior, evidence, and rollback.
2. Branch from main using feature/, fix/, docs/, or lab/.
3. Keep commits small and never include credentials, account identifiers, private URLs, real customer data, Terraform state, or unsanitized screenshots.
4. Run the affected tests and security checks locally.
5. Open a pull request using the repository template.
6. Merge only after required CI checks pass.

Use Conventional Commit subjects such as feat(api): add order transition validation.
Releases use Semantic Versioning and immutable Git tags such as v0.1.0.

## Evidence

For cloud labs, record only sanitized evidence. State whether each result is Confirmed, Partial, Unavailable, Unverified, or Failed. A successful command exit code alone is not proof that a deployment is healthy or that teardown is complete.
