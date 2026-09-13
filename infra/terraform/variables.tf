variable "deploy_enabled" {
  description = "Master safety switch. No managed resources are created while false."
  type        = bool
  default     = false
}

variable "enable_notifier" {
  description = "Create the Lambda notifier and EventBridge target. Requires deploy_enabled and a packaged artifact."
  type        = bool
  default     = false
}

variable "expected_account_id" {
  description = "Exact 12-digit AWS account that is allowed when deployment is enabled. Never commit a real value."
  type        = string
  default     = ""
}

variable "expected_role_arn_pattern" {
  description = "Optional regular expression that the current caller ARN must match."
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "Provider Region. Personal-learning defaults to us-east-1; enterprise values must be discovered."
  type        = string
  default     = "us-east-1"
}

variable "expected_region" {
  description = "Exact Region allowed when deployment is enabled."
  type        = string
  default     = ""
}

variable "environment" {
  description = "Isolated learning environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "eks-lab"], var.environment)
    error_message = "environment must be dev or eks-lab."
  }
}

variable "owner" {
  description = "Non-secret owner tag value."
  type        = string
  default     = ""
}

variable "expires_on" {
  description = "Mandatory lab expiry tag in YYYY-MM-DD form."
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "Two explicitly reviewed AZ names in aws_region."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  type    = string
  default = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.0.0/24", "10.42.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.42.10.0/24", "10.42.11.0/24"]
}

variable "lambda_package_path" {
  description = "Path to a locally packaged notifier zip. The zip is deliberately not stored in Git."
  type        = string
  default     = ""
}

variable "websocket_management_endpoint" {
  description = "HTTPS API Gateway management endpoint; required only when the notifier is enabled."
  type        = string
  default     = ""
}

variable "websocket_manage_connections_arn" {
  description = "Exact execute-api ManageConnections resource ARN; required only when the notifier is enabled."
  type        = string
  default     = ""
}
