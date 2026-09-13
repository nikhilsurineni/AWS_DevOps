# Learning Roadmap

The 32-week curriculum runs from 14 September 2026 through 25 April 2027 at 4–6 hours per week.

Each week follows the same evidence loop:

1. Review the concept, operational responsibility, and cost dimensions.
2. Build one bounded hands-on lab.
3. Exercise at least one failure or denied-action case.
4. Record sanitized evidence and a short learning journal entry.
5. Review cost and verify teardown.

## Milestones

| Weeks | Milestone | Exit evidence |
| --- | --- | --- |
| 1–4 | Account, toolchain, Git, and IAM | Verified account boundary, repository, temporary authentication, and denied-action test |
| 5–8 | VPC, EC2, storage, and databases | Packet-path diagram, private database lab, restore test, and teardown inventory |
| 9–12 | Local and serverless OrderFlow | Tested vertical slice, queued processing, realtime update, CI, and Free Plan exit evidence |
| 13–20 | Docker, ECS, CloudFormation, and Terraform | Immutable image, ECS rollback, native IaC comparison, and reproducible Terraform stack |
| 21–26 | CI/CD, Kubernetes, and EKS | Gated pipeline, local Helm release, same-day EKS deployment, and verified destruction |
| 27–32 | Security, reliability, and portfolio | Clean-room ECS deployment, failure drills, threat model, runbook, final demo, and no-orphan evidence |

Detailed lab checklists live under `docs/labs/` and are completed sequentially.
