output "acr_id" {
  description = "The ID of the created Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "acr_name" {
  description = "The name of the created Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "The login server URL of the ACR (e.g. myregistry.azurecr.io)"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "The admin username for the ACR. Only populated when admin_enabled = true."
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "The admin password for the ACR. Only populated when admin_enabled = true."
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "acr_principal_id" {
  description = "The Principal ID of the System Assigned Managed Identity on the ACR, if enabled."
  value       = try(azurerm_container_registry.acr.identity[0].principal_id, null)
}
