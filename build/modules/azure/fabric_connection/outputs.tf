output "connection_id" {
  description = "GUID of the Fabric connection — fetched live from the API on every apply."
  value       = data.external.connection_id.result.id
}

output "connection_display_name" {
  description = "Display name of the connection."
  value       = var.display_name
}

output "connection_type" {
  description = "Connector type (PostgreSQL / Oracle / Warehouse)."
  value       = var.connection_type
}
