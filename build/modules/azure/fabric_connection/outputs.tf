output "connection_id" {
  description = "GUID of the created Fabric connection — pass this to fabric_copy_job."
  value       = fabric_connection.this.id
}

output "connection_display_name" {
  description = "Display name."
  value       = fabric_connection.this.display_name
}

output "connection_type" {
  description = "Connector type (PostgreSQL / Oracle)."
  value       = var.connection_type
}
