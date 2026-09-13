# Acceptance Matrix

| Requirement | Authoritative source | Changed seam | Focused check | Final check | Rollback |
| --- | --- | --- | --- | --- | --- |
| Valid state transitions | Domain state machine | API and worker | Unit/property tests | End-to-end order lifecycle | Redeploy prior image digest |
| Idempotent processing | `order_events.event_id` uniqueness | Worker/database | Duplicate-event integration test | Replay a delivered queue message | Stop consumer and restore prior digest |
| Near-real-time update | Accepted event timestamp and browser receipt | Worker/notifier/UI | WebSocket contract test | 95% visible within five seconds | Disable notifier and retain REST reads |
| Private durable data | Database and network configuration | Terraform/RDS | Static and policy checks | Runtime connectivity plus public-access denial | Destroy lab stack |
| Temporary workload identity | IAM role/session evidence | EC2/ECS/Lambda/EKS/CI | Policy and denied-action tests | Redacted caller identity per runtime | Remove role trust or destroy stack |
| Reproducible deployment | Git commit, image digest, Terraform state | CI/CD and IaC | Validate/build/plan | Clean-checkout deploy and smoke test | Deploy prior digest and prior Terraform revision |
| Cost-bounded teardown | AWS inventory and billing evidence | IaC/runbooks | Destroy plan and resource list | Independent post-destroy inventory | Stop creation and remove exact leftovers |
| Public portfolio safety | Repository contents | All modules | Secret/internal-metadata scan | Release archive inspection | Remove affected history and rotate exposed material |

Status vocabulary is `Confirmed`, `Partial`, `Unavailable`, `Unverified`, or `Failed`.
