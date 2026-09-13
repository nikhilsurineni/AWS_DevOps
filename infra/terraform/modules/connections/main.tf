variable "enabled" { type = bool }
variable "name_prefix" { type = string }

resource "aws_dynamodb_table" "connections" {
  count = var.enabled ? 1 : 0

  name         = "${var.name_prefix}-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }
}

output "table_name" {
  value = try(aws_dynamodb_table.connections[0].name, null)
}

output "table_arn" {
  value = try(aws_dynamodb_table.connections[0].arn, null)
}
