# OrderFlow Terraform baseline

This root is deliberately inert: `deploy_enabled` defaults to `false`, and every resource is gated by it. Enabling it requires an exact account, Region, two AZs, owner, and expiry date. The guard queries STS and fails closed on a mismatch. It never creates a NAT Gateway.

## Safe local validation

```powershell
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform fmt -check -recursive
terraform -chdir=infra/terraform validate
terraform -chdir=infra/terraform plan -refresh=false -var-file=examples/dev.tfvars.example
```

The example plan must show no changes because its deployment switch is off. Do not rename an example to a real `.tfvars` file in Git. Run `scripts/aws-account-preflight.ps1` immediately before any future plan or apply with deployment enabled.

Remote state is intentionally not bootstrapped here. Configure a reviewed, versioned and encrypted state backend later; never pass secrets as ordinary Terraform variables because they can persist in state.
