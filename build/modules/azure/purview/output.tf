# modules/azure/purview/outputs.tf

output "purview_id" {
  description = "Resource ID of the Purview account — the one created here, or the existing tenant account this module attached to."
  value       = local.account_id
}

output "purview_name" {
  description = "Name of the Purview account."
  value       = local.account_name
}

output "purview_resource_group_name" {
  description = "Resource group holding the Purview account."
  value       = local.account_rg
}

output "purview_created_here" {
  description = "Whether this configuration owns the account lifecycle, or is attached to an account managed elsewhere."
  value       = local.created != null
}

output "purview_identity_principal_id" {
  description = "Object ID of the Purview system-assigned managed identity. Add this to the Entra security group allowed to use the Fabric read-only admin APIs."
  value       = local.account_identity_principal_id
}

output "purview_catalog_endpoint" {
  description = "Catalog (Atlas) endpoint of the Purview account."
  value       = local.created != null ? local.created.catalog_endpoint : try(data.azapi_resource.existing[0].output.properties.endpoints.catalog, null)
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
