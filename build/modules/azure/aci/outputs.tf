output "aci_id" {
  description = "The ID of the created Azure Container Group"
  value       = azurerm_container_group.aci.id
}

output "aci_name" {
  description = "The name of the created Azure Container Group"
  value       = azurerm_container_group.aci.name
}

output "aci_fqdn" {
  description = "The FQDN of the container group (if a DNS label was assigned)"
  value       = azurerm_container_group.aci.fqdn
}

output "aci_ip_address" {
  description = "The IP address of the container group (private IP when vnet_mode = true)"
  value       = azurerm_container_group.aci.ip_address
}

output "managed_identity_id" {
  description = "Resource ID of the User Assigned Managed Identity. Null when vnet_mode = true (Azure does not support MSI on VNet-injected container groups)."
  value       = local.use_identity ? azurerm_user_assigned_identity.aci[0].id : var.user_assigned_identity_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the User Assigned Managed Identity. Null when vnet_mode = true."
  value       = local.use_identity ? azurerm_user_assigned_identity.aci[0].principal_id : var.managed_identity_principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity. Null when vnet_mode = true."
  value       = local.use_identity ? azurerm_user_assigned_identity.aci[0].client_id : null
}
