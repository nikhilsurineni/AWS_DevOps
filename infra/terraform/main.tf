locals {
  name_prefix = "orderflow-${var.environment}"
  required_tags = {
    Project     = "OrderFlow"
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    ExpiresOn   = var.expires_on
  }
}

data "aws_caller_identity" "current" {
  count = var.deploy_enabled ? 1 : 0
}

resource "terraform_data" "deployment_guard" {
  count = var.deploy_enabled ? 1 : 0

  input = {
    account     = data.aws_caller_identity.current[0].account_id
    caller_arn  = data.aws_caller_identity.current[0].arn
    region      = var.aws_region
    environment = var.environment
  }

  lifecycle {
    precondition {
      condition     = can(regex("^[0-9]{12}$", var.expected_account_id))
      error_message = "Set expected_account_id to the exact reviewed 12-digit account before enabling deployment."
    }
    precondition {
      condition     = data.aws_caller_identity.current[0].account_id == var.expected_account_id
      error_message = "Current AWS account does not match expected_account_id."
    }
    precondition {
      condition     = var.expected_region != "" && var.aws_region == var.expected_region
      error_message = "aws_region must exactly match expected_region."
    }
    precondition {
      condition     = var.expected_role_arn_pattern == "" || can(regex(var.expected_role_arn_pattern, data.aws_caller_identity.current[0].arn))
      error_message = "Current caller ARN does not match expected_role_arn_pattern."
    }
    precondition {
      condition     = length(var.owner) > 1 && can(regex("^20[0-9]{2}-[0-9]{2}-[0-9]{2}$", var.expires_on))
      error_message = "owner and a YYYY-MM-DD expires_on tag are mandatory."
    }
    precondition {
      condition     = length(var.availability_zones) == 2
      error_message = "Exactly two reviewed availability_zones are required."
    }
    precondition {
      condition     = length(var.public_subnet_cidrs) == 2 && length(var.private_subnet_cidrs) == 2
      error_message = "Exactly two public and two private subnet CIDRs are required."
    }
    precondition {
      condition = alltrue([
        for subnet in concat(var.public_subnet_cidrs, var.private_subnet_cidrs) :
        try(cidrcontains(var.vpc_cidr, cidrhost(subnet, 0)), false)
      ])
      error_message = "Every subnet CIDR must be valid and contained by vpc_cidr."
    }
    precondition {
      condition = length(distinct(concat(var.public_subnet_cidrs, var.private_subnet_cidrs))) == 4 && alltrue(flatten([
        for left_index, left in concat(var.public_subnet_cidrs, var.private_subnet_cidrs) : [
          for right_index, right in concat(var.public_subnet_cidrs, var.private_subnet_cidrs) :
          left_index == right_index || try(!cidrcontains(left, cidrhost(right, 0)) && !cidrcontains(right, cidrhost(left, 0)), false)
        ]
      ]))
      error_message = "Public and private subnet CIDRs must be unique and non-overlapping."
    }
    precondition {
      condition     = !var.enable_notifier || (var.lambda_package_path != "" && fileexists(var.lambda_package_path))
      error_message = "Package the notifier and set lambda_package_path before enabling it."
    }
    precondition {
      condition     = !var.enable_notifier || (startswith(var.websocket_management_endpoint, "https://") && startswith(var.websocket_manage_connections_arn, "arn:aws:execute-api:"))
      error_message = "The notifier requires an HTTPS management endpoint and an exact execute-api ARN."
    }
  }
}

module "network" {
  source = "./modules/network"

  enabled              = var.deploy_enabled
  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  depends_on = [terraform_data.deployment_guard]
}

module "registry" {
  source = "./modules/registry"

  enabled     = var.deploy_enabled
  name_prefix = local.name_prefix

  depends_on = [terraform_data.deployment_guard]
}

module "connections" {
  source = "./modules/connections"

  enabled     = var.deploy_enabled
  name_prefix = local.name_prefix

  depends_on = [terraform_data.deployment_guard]
}

module "notifier" {
  source = "./modules/notifier"

  enabled                          = var.deploy_enabled && var.enable_notifier
  name_prefix                      = local.name_prefix
  package_file                     = var.lambda_package_path
  connections_table_name           = module.connections.table_name
  connections_table_arn            = module.connections.table_arn
  websocket_management_endpoint    = var.websocket_management_endpoint
  websocket_manage_connections_arn = var.websocket_manage_connections_arn
}

module "eventing" {
  source = "./modules/eventing"

  enabled     = var.deploy_enabled
  name_prefix = local.name_prefix
  environment = var.environment
  lambda_arn  = module.notifier.function_arn
  lambda_name = module.notifier.function_name
}

module "observability" {
  source = "./modules/observability"

  enabled     = var.deploy_enabled
  name_prefix = local.name_prefix
  queue_name  = module.eventing.queue_name
  dlq_name    = module.eventing.dlq_name
  lambda_name = module.notifier.function_name
}
