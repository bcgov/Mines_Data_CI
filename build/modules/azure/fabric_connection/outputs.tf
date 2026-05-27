output "connection_id" {
  description = "GUID of the created Fabric connection."
  value       = trimspace(data.local_file.connection_id.content)
}

output "connection_display_name" {
  description = "Display name of the connection."
  value       = var.display_name
}

output "connection_type" {
  description = "Connector type (PostgreSQL / Oracle / Warehouse)."
  value       = var.connection_type
}
