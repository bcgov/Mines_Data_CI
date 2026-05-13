output "gateway_id" {
  description = "Fabric gateway resource ID"
  value       = fabric_gateway.this.id
}

output "gateway_name" {
  description = "Display name of the gateway"
  value       = local.gateway_name
}

output "gateway_capacity_id" {
  description = "Capacity ID assigned to the gateway"
  value       = fabric_gateway.this.capacity_id
}
