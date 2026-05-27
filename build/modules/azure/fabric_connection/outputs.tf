output "connection_id" {
  description = "GUID of the Fabric connection — stored in Terraform state."
  value       = data.external.connection_id.result.id
}

output "connection_display_name" {
  value = var.display_name
}

output "connection_type" {
  value = var.connection_type
}
