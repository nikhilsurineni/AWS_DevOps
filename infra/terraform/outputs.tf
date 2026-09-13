output "deployment_enabled" {
  value       = var.deploy_enabled
  description = "False means this configuration manages no AWS resources."
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "ecr_repository_urls" {
  value = module.registry.repository_urls
}

output "order_queue_url" {
  value = module.eventing.queue_url
}

output "event_bus_name" {
  value = module.eventing.event_bus_name
}

output "connections_table_name" {
  value = module.connections.table_name
}

output "notifier_function_name" {
  value = module.notifier.function_name
}
