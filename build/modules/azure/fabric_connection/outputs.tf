output "connection_id" {
  description = "GUID of the Fabric connection — stored in state after first apply."
  value       = null_resource.fabric_connection.triggers["connection_id"]
}

output "connection_display_name" {
  value = var.display_name
}

output "connection_type" {
  value = var.connection_type
}
