# AWS lab preflight and cleanup

## Before any plan or mutation

1. Confirm the visible console account, role, Region, and environment.
2. Record the estimate, required tags, expiry, success evidence, and teardown order.
3. Validate the CLI independently without displaying credentials:

   ```powershell
   .\scripts\aws-account-preflight.ps1 `
     -ExpectedAccountId '<exact-account-id>' `
     -ExpectedRegion '<exact-region>' `
     -Profile '<reviewed-profile>'
   ```

4. Keep Terraform `deploy_enabled=false` until the preflight succeeds. Never
   commit account IDs, role names, generated tfvars, state, or plan files.
5. Review `terraform plan` for resource count, public exposure, tags, and
   unexpected replacement. This runbook does not authorize Production or shared
   accounts.

## Teardown verification

Run the read-only inventory before and after teardown:

```powershell
.\scripts\aws-cleanup-inventory.ps1 `
  -ExpectedAccountId '<exact-account-id>' `
  -ExpectedRegion '<exact-region>' `
  -Profile '<reviewed-profile>'
```

The default output includes project-tagged counts plus account-wide regional
counts, but not identifiers. Use `-IncludeTaggedIdentifiers` only for a
controlled local troubleshooting session; never publish that output.

`terraform destroy` is not proof of cleanup. Independently check EKS and node
groups, ECS tasks, EC2/EBS/EIPs/ENIs, load balancers and target groups, RDS and
snapshots, NAT gateways, ECR images, Lambda, queues/DLQs, DynamoDB, API Gateway,
CloudWatch logs/alarms, and temporary S3 objects. Report denied or unsupported
checks as Unavailable, never as zero.

## Rollback

Infrastructure rollback is the last reviewed Terraform state and immutable
application image digest. A lab teardown is intentionally destructive and must
be requested for the exact reviewed environment; these read-only scripts never
delete resources.
