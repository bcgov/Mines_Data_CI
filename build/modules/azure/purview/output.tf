# modules/azure/purview/outputs.tf

output "purview_id" {
  description = "The ID of the created Purview account."
  value       = azurerm_purview_account.this.id
}

output "purview_name" {
  description = "The name of the created Purview account."
  value       = azurerm_purview_account.this.name
}

output "purview_identity_principal_id" {
  description = "Object ID of the Purview system-assigned managed identity. Add this to the Entra security group allowed to use the Fabric read-only admin APIs."
  value       = azurerm_purview_account.this.identity[0].principal_id
}

output "purview_catalog_endpoint" {
  description = "Catalog (Atlas) endpoint of the Purview account."
  value       = azurerm_purview_account.this.catalog_endpoint
}

output "purview_scan_endpoint" {
  description = "Scanning data-plane endpoint of the Purview account."
  value       = local.scan_endpoint
}

output "purview_collection_name" {
  description = "Reference name of the root collection the data source is registered under."
  value       = local.collection_name
}

output "fabric_datasource_name" {
  description = "Name of the registered Fabric data source."
  value       = local.fabric_datasource_name
}

output "fabric_scan_name" {
  description = "Name of the Fabric scan."
  value       = local.fabric_scan_name
}

output "fabric_scan_workspace_uris" {
  description = "Workspace URI prefixes the scan is scoped to. Empty means the whole tenant is scanned."
  value       = local.workspace_uri_prefixes
}
