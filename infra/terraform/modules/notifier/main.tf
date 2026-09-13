variable "enabled" { type = bool }
variable "name_prefix" { type = string }
variable "package_file" { type = string }
variable "connections_table_name" { type = string }
variable "connections_table_arn" { type = string }
variable "websocket_management_endpoint" { type = string }
variable "websocket_manage_connections_arn" { type = string }

resource "aws_cloudwatch_log_group" "this" {
  count = var.enabled ? 1 : 0

  name              = "/aws/lambda/${var.name_prefix}-realtime-notifier"
  retention_in_days = 7
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  count = var.enabled ? 1 : 0

  name               = "${var.name_prefix}-realtime-notifier"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
}

data "aws_iam_policy_document" "runtime" {
  count = var.enabled ? 1 : 0

  statement {
    sid       = "WriteOwnLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.this[0].arn}:*"]
  }

  statement {
    sid       = "ManageConnectionRegistry"
    actions   = ["dynamodb:Scan", "dynamodb:DeleteItem"]
    resources = [var.connections_table_arn]
  }

  statement {
    sid       = "PushWebSocketMessages"
    actions   = ["execute-api:ManageConnections"]
    resources = [var.websocket_manage_connections_arn]
  }
}

resource "aws_iam_role_policy" "runtime" {
  count = var.enabled ? 1 : 0

  name   = "runtime"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.runtime[0].json
}

resource "aws_lambda_function" "this" {
  count = var.enabled ? 1 : 0

  function_name    = "${var.name_prefix}-realtime-notifier"
  role             = aws_iam_role.this[0].arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.13"
  architectures    = ["arm64"]
  filename         = var.package_file
  source_code_hash = var.enabled ? filebase64sha256(var.package_file) : null
  memory_size      = 128
  timeout          = 15

  environment {
    variables = {
      CONNECTIONS_TABLE             = var.connections_table_name
      WEBSOCKET_MANAGEMENT_ENDPOINT = var.websocket_management_endpoint
      MAX_CONNECTIONS               = "1000"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy.runtime,
  ]
}

output "function_name" {
  value = try(aws_lambda_function.this[0].function_name, null)
}

output "function_arn" {
  value = try(aws_lambda_function.this[0].arn, null)
}
