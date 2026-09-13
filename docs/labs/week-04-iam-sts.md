# Week 4: IAM and STS

Status: **Partial** on 13 September 2026. The policy and verification script are locally
validated, Access Analyzer and a service-linked role were inspected, and the custom-policy
simulation passed in the personal-learning console. A workload-role exercise remains pending.

## Concepts to explain before the lab

- Authentication establishes who the caller is; authorization determines what the caller may do.
- An IAM user is a long-lived identity. A role is assumed to obtain a temporary STS session.
- Identity policies grant permissions to a principal. Resource policies grant access at a resource.
- An explicit deny overrides an allow. Anything not allowed remains implicitly denied.
- Service roles, EC2 instance profiles, ECS task roles, Lambda execution roles, and EKS workload
  identity prevent applications from carrying long-lived access keys.
- A permissions boundary limits maximum identity permissions but does not grant permissions.
- Service control policies limit accounts in an organization but do not grant permissions.

## Safe simulation

The sample policy permits two read-only metadata calls, explicitly denies selected IAM mutations,
and leaves unrelated actions implicitly denied. The script calls the IAM policy simulator; it does
not attach the policy or create an identity.

```powershell
.\scripts\test-iam-policy.ps1 -Profile personal-learning -Region us-east-1
```

| Action | Expected decision | Reason |
| --- | --- | --- |
| `iam:GetAccountSummary` | `allowed` | Exact allow statement |
| `iam:CreateUser` | `explicitDeny` | Exact deny statement |
| `iam:CreateAccessKey` | `explicitDeny` | Exact deny statement |
| `s3:ListAllMyBuckets` | `implicitDeny` | No matching allow |

If the learning identity lacks `iam:SimulateCustomPolicy`, record the result as **Unavailable**;
do not broaden its permissions merely to make this lab pass.

## Guided AWS checkpoint

1. Verify the personal-learning account, current principal, and `us-east-1` separately.
2. Review the signed-in principal's policies and last-accessed information without exposing identifiers.
3. Open IAM Access Analyzer and distinguish account analyzers from policy validation.
4. Inspect one AWS service-linked role and one workload role, without editing either.
5. Run the custom-policy simulation and capture only action/decision pairs.
6. Use CloudTrail Event history to locate the read-only simulation request when available.

## Confirmed console evidence

- The intended credit-backed learning account and `us-east-1` were visible before inspection.
- IAM Access Analyzer showed its getting-started page, so no analyzer was configured.
- The console distinguished external, internal, and unused-access analysis.
- The displayed pricing made external-access analysis free, while internal and unused-access
  analysis were paid capabilities. These values are a dated console observation, not a budget estimate.
- No analyzer was created because the free Week 4 objective is policy reasoning and read-only discovery.
- The roles inventory contained five AWS service-linked roles and no application workload role.
- The inspected Auto Scaling service-linked role used an AWS-managed service policy, a one-hour
  maximum session duration, and a trust policy limited to the Auto Scaling service principal calling
  `sts:AssumeRole`.
- The role, its permissions, and its trust relationship were inspected without modification.
- The custom policy existed only inside the simulator and was not created or attached in IAM.
- `iam:GetAccountSummary` returned **Allowed** from one explicit allow statement.
- `iam:CreateUser` and `iam:CreateAccessKey` returned **Denied** because an explicit deny matched.
- `s3:ListAllMyBuckets` returned **Denied** because no statement allowed it (implicit deny).

## Evidence and cleanup

- Record action/decision pairs only; omit account and principal identifiers.
- The simulation creates no policy, role, user, or access key, so no cloud teardown is expected.
- If a later hands-on role is created, give it an expiry tag and delete it in the same lab session.
- Never create a persistent access key for OrderFlow.
- Current cloud teardown result: no Week 4 resources were created, so none required removal.
