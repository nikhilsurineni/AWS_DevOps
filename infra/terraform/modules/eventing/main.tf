variable "enabled" { type = bool }
variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "lambda_arn" {
  type    = string
  default = null
}
variable "lambda_name" {
  type    = string
  default = null
}

resource "aws_sqs_queue" "dlq" {
  count = var.enabled ? 1 : 0

  name                      = "${var.name_prefix}-orders-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "orders" {
  count = var.enabled ? 1 : 0

  name                       = "${var.name_prefix}-orders"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = 5
  })
}

resource "aws_cloudwatch_event_bus" "this" {
  count = var.enabled ? 1 : 0
  name  = "${var.name_prefix}-events"
}

resource "aws_cloudwatch_event_rule" "order_status" {
  count = var.enabled ? 1 : 0

  name           = "${var.name_prefix}-order-status"
  event_bus_name = aws_cloudwatch_event_bus.this[0].name
  event_pattern = jsonencode({
    source        = ["orderflow-worker"]
    "detail-type" = ["Order Status Changed"]
    detail = {
      schema_version = ["1.0"]
      environment    = [var.environment]
    }
  })
}

resource "aws_cloudwatch_event_target" "notifier" {
  count = var.enabled && var.lambda_arn != null ? 1 : 0

  rule           = aws_cloudwatch_event_rule.order_status[0].name
  event_bus_name = aws_cloudwatch_event_bus.this[0].name
  arn            = var.lambda_arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }
}

resource "aws_lambda_permission" "eventbridge" {
  count = var.enabled && var.lambda_arn != null && var.lambda_name != null ? 1 : 0

  statement_id  = "AllowEventBridgeOrderStatus"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.order_status[0].arn
}

output "queue_name" {
  value = try(aws_sqs_queue.orders[0].name, null)
}

output "queue_url" {
  value = try(aws_sqs_queue.orders[0].url, null)
}

output "dlq_name" {
  value = try(aws_sqs_queue.dlq[0].name, null)
}

output "event_bus_name" {
  value = try(aws_cloudwatch_event_bus.this[0].name, null)
}
