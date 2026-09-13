terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # The inert path uses explicit non-secret placeholders so local and CI plans
  # never fall back to a developer profile. Real deployments use the reviewed
  # ambient temporary credentials after the account guard is enabled.
  access_key = var.deploy_enabled ? null : "unused-local-validation"
  secret_key = var.deploy_enabled ? null : "unused-local-validation"

  # Permit credential-free validation only while the resource switch is off.
  skip_credentials_validation = !var.deploy_enabled
  skip_requesting_account_id  = !var.deploy_enabled
  skip_metadata_api_check     = !var.deploy_enabled
  skip_region_validation      = !var.deploy_enabled

  default_tags {
    tags = local.required_tags
  }
}
