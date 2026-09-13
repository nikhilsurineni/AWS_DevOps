# OrderFlow AWS and DevOps Learning Handbook

Revision: 13 September 2026

This handbook turns the [32-week roadmap](roadmap.md) into a repeatable teaching and execution
process. It is the operating guide for every lesson; individual lab records hold the exact service
settings and sanitized evidence.

## Learning ownership contract

- The learner creates, changes, and deletes every AWS resource manually during the lesson for that topic.
- Codex explains concepts, reviews the visible target and estimate, guides small blocks of steps,
  performs read-only verification, and prepares local code, tests, diagrams, and documentation.
- Codex does not click AWS create/update/delete controls and does not execute AWS mutation commands.
- Authentication secrets, MFA, CAPTCHA, trusted-device actions, credentials, and secret values are user-only.
- A later topic is not deployed early merely because its code or guide is ready.
- Personal and enterprise environments never share credentials, state, identifiers, evidence, or pipelines.

## Standard lesson loop

Every lesson uses these eight gates:

1. **Explain:** define the service, its problem, alternatives, failure modes, and when not to use it.
2. **Predict:** answer two or three scenario questions before touching AWS.
3. **Preflight:** verify visible account, role, Region, environment, expected resources, tags, estimate,
   evidence, teardown order, and time limit.
4. **Build:** the learner performs one small group of console actions at a time.
5. **Prove:** verify rendered state and, when available, a separate read-only API or CLI signal.
6. **Break:** perform a bounded negative or failure test and predict its result first.
7. **Explain back:** the learner describes the packet, identity, data, deployment, or event path.
8. **Teardown and journal:** the learner removes temporary resources; both console and bounded inventory
   must show no unintended leftovers before the lesson is marked complete.

Evidence states are **Confirmed**, **Partial**, **Unavailable**, **Unverified**, and **Failed**. A plan,
successful click, or command exit code is not proof of a deployed result.

## Accounts and cost rules

| Environment | Allowed use | Prohibited use |
| --- | --- | --- |
| Local WSL | Code, tests, Docker, Compose, Terraform validation, local Kubernetes | Real secrets in source or images |
| Personal learning | Weeks 1–12 foundations and approved short labs | Production data, NAT Gateway, persistent costly services |
| Enterprise sandbox | Later bounded ECS/EKS/IaC labs after governance verification | Shared/Production accounts; public-repository federation without approval |

Before every AWS lesson, record the current signed-in estimate. Billing evidence that is unavailable
is reported as **Unavailable**, never as USD 0. Resources with hourly charges are same-session labs.
The personal ceiling is USD 10 per month; the enterprise-session target is below USD 5 unless its
sandbox governance is stricter.

Required tags are `Project=OrderFlow`, an explicit `Environment`, a non-sensitive `Owner`,
`ManagedBy`, and `ExpiresOn`. Account IDs, email addresses, corporate names, and internal identifiers
never enter the public repository.

## Curriculum execution map

The dates and detailed technical outcomes remain authoritative in the roadmap. The table below states
what the learner does, what must be proven, and the teardown class for each week.

| Week | Learner exercise | Exit evidence | Teardown class |
| --- | --- | --- | --- |
| 1 | Inspect account plan, credits, budgets, root posture, Regions, and quotas | Budget alerts and sanitized plan/expiry record | Persistent budget only |
| 2 | Validate WSL, Git, Python, Node, AWS CLI, Docker, Terraform, Kubernetes tools | Version matrix and focused smoke commands | Local only |
| 3 | Practice branch, commit, push, pull request, failed check, fix, tag | Public repository and green CI | Keep repository |
| 4 | Simulate allow, explicit deny, and implicit deny; inspect roles and STS | Four policy decisions and trust-policy explanation | No AWS resource |
| 5 | Manually build a two-AZ VPC with public/private routing and no NAT | Packet-path explanation and route associations | Same session |
| 6 | Launch one EC2 host and use SSM without SSH | IMDSv2, EBS, health-failure and recovery evidence | Same session |
| 7 | Serve a private versioned S3 origin through CloudFront OAC | HTTPS page, direct-S3 denial, version restore, cache test | Same session; start early |
| 8 | Create private Single-AZ PostgreSQL and test migration/restore | SG-to-SG ingress, migration and restore proof | Same session |
| 9 | Build the local API/web/PostgreSQL vertical slice | Tests, logs, correlation ID, synthetic UI flow | Local only |
| 10 | Deploy a small Lambda/API Gateway endpoint and validate JWT behavior | Version/alias, timeout and authorization tests | Same session |
| 11 | Connect SQS, DLQ, EventBridge, WebSocket, and DynamoDB TTL | Duplicate, retry, DLQ, connection-cleanup evidence | Same session |
| 12 | Demonstrate serverless MVP and OIDC-based personal deployment | Create-to-WebSocket flow and green CI | Destroy charge-bearing stack |
| 13 | Verify enterprise sandbox governance and identity boundaries | Sanitized operating contract; no Production reachability | No workload yet |
| 14 | Containerize API, worker, and web as non-root images | Reproducible multi-stage builds and health checks | Local only |
| 15 | Run Compose; push one SHA image to ECR; scan and create SBOM | Digest, scan, SBOM, lifecycle policy | Delete old images |
| 16 | Manually deploy ECS Fargate API and worker | Task/execution role separation, logs, health, replacement | Same session unless approved |
| 17 | Add bounded ALB and test rolling deployment and rollback | Circuit breaker, scaling concept, prior-digest rollback | Same session |
| 18 | Deploy a small CloudFormation stack and inspect change/drift events | Change set, update rollback, drift and deletion | Same session |
| 19 | Apply a minimal Terraform stack after exact plan review | Plan/apply/no-drift/destroy evidence | Same session |
| 20 | Exercise modules, state keys, import, drift, and replacement | Clean plan and complete post-destroy inventory | Same session |
| 21 | Make CI reject defective backend, frontend, image, and Terraform changes | Required checks block the pull request | No AWS mutation |
| 22 | Build once, publish one digest, deploy, smoke-test, and roll back | Release metadata and same-digest proof | Destroy temporary runtime |
| 23 | Deploy OrderFlow to kind or Minikube | Probes, limits, rollout, ConfigMap/Secret behavior | Local cluster |
| 24 | Package Helm chart and test RBAC, NetworkPolicy, HPA/PDB, rollback | Denial, replacement, history and rollback evidence | Local cluster |
| 25 | Model EKS identity, networking, upgrades, support, and exact cost | Reviewed four-hour estimate and teardown dependency graph | No cluster |
| 26 | Manually create minimal EKS, deploy, break, recover, and destroy | Identity, probes, logs, pod replacement, zero leftovers | Four-hour hard limit |
| 27 | Integrate API, RDS, queues, events, notifier, and WebSocket | Idempotency, ordering, retry, DLQ replay evidence | Bounded dev stack |
| 28 | Add Cognito, workload roles, secret storage, KMS concepts, and scans | Negative authorization and least-privilege proof | Bounded dev stack |
| 29 | Add logs, metrics, alarms, dashboard, SLI and SLO | Correlation trace and alarm-state evidence | Short retention |
| 30 | Run container, message, dependency, database, and release incidents | RTO/RPO, restore, self-heal and rollback record | Restore then destroy |
| 31 | Perform clean-checkout ECS reference deployment | Test/build/provision/deploy/demo/recover/destroy transcript | Same session |
| 32 | Publish portfolio release and conduct knowledge review | Sanitized portfolio, demo, release tag, interview review | Zero unintended AWS resources |

## Knowledge checks by domain

For each service, the learner must be able to answer:

- What problem does it solve, and what is a credible alternative?
- Is it global, regional, zonal, or edge-distributed?
- Which identity assumes which role, and what is the smallest required permission?
- What network path does a request or event take in both directions?
- What data is durable, encrypted, backed up, replicated, cached, or eventually consistent?
- Which metric and log would reveal failure first?
- What is billed by hour, request, capacity, storage, transfer, address, or log volume?
- How is it reproduced, rolled back, and completely removed?

## Git and delivery workflow

1. One topic per branch using `docs/`, `feat/`, `fix/`, or `infra/` prefixes.
2. CI runs before merge; failed checks are diagnosed rather than bypassed.
3. Pull requests contain scope, validation, remaining gaps, cost impact, and rollback.
4. Images use commit-SHA tags; deployments record and reuse the immutable digest.
5. GitHub-to-personal-AWS OIDC is narrowly scoped. Enterprise deployment uses an approved enterprise
   repository or explicit governance approval, never an assumed trust from the public repository.
6. Account IDs, role ARNs, environment URLs, credentials, Terraform state, plan files, and unsanitized
   screenshots remain outside Git.

## Lab completion record

Each lab record contains:

- date, environment, Region, objective, expected resources, estimate, and teardown deadline;
- the learner's explanation of the architecture and identity flow;
- exact tests, negative tests, and observed results;
- sanitized cost evidence and resource counts;
- teardown evidence plus unavailable inventory checks;
- a final status and the smallest remaining gap.

A week is complete only after its exit evidence is proven. Prepared documentation or prebuilt code
alone never completes a hands-on AWS milestone.

## Emergency stop and cleanup

If the account, role, Region, estimate, resource list, or ownership is uncertain, stop before mutation.
If an unexpected billable resource appears, identify its dependencies and let the learner remove only
the exact verified resource in safe dependency order. Never use broad wildcards, recursive deletion,
or an unreviewed `terraform destroy`. Preserve evidence of permission-denied inventory checks and ask
the account owner for the smallest missing read permission when necessary.

The durable outcome is the reproducible public repository and the learner's demonstrated understanding,
not a permanently running AWS environment.
