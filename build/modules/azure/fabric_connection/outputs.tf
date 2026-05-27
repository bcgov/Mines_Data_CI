output "connection_id" {
  description = "GUID of the created Fabric connection — pass this to fabric_copy_job."
  value       = azapi_resource.this.id
}

output "connection_display_name" {
  description = "Display name."
  value       = var.display_name
}

output "connection_type" {
  description = "Connector type (PostgreSQL / Oracle / Warehouse)."
  value       = var.connection_type
}