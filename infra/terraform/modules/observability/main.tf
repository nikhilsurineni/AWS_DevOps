variable "enabled" { type = bool }
variable "name_prefix" { type = string }
variable "queue_name" { type = string }
variable "dlq_name" { type = string }
variable "lambda_name" {
  type    = string
  default = null
}

resource "aws_cloudwatch_metric_alarm" "oldest_message" {
  count = var.enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-oldest-order-message"
  alarm_description   = "OrderFlow queue has a message older than five minutes."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateAgeOfOldestMessage"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 300
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { QueueName = var.queue_name }
}

resource "aws_cloudwatch_metric_alarm" "dlq_visible" {
  count = var.enabled ? 1 : 0

  alarm_name          = "${var.name_prefix}-dlq-visible"
  alarm_description   = "One or more OrderFlow events require DLQ investigation."
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { QueueName = var.dlq_name }
}

resource "aws_cloudwatch_metric_alarm" "notifier_errors" {
  count = var.enabled && var.lambda_name != null ? 1 : 0

  alarm_name          = "${var.name_prefix}-notifier-errors"
  alarm_description   = "The real-time notifier returned a Lambda error."
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = { FunctionName = var.lambda_name }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.enabled ? 1 : 0

  dashboard_name = "${var.name_prefix}-operations"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Order event queues"
          view    = "timeSeries"
          stacked = false
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", var.queue_name],
            [".", ".", "QueueName", var.dlq_name],
          ]
          period = 60
          stat   = "Maximum"
        }
      }
    ]
  })
}
