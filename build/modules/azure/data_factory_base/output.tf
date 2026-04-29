# modules/key_vaults/outputs.tf

output "adf_id" {
  description = "The id of the created Azure adf app"
  value       = azurerm_data_factory.adf.id
}

output "adf_identity_id" {
  description = "The id of the created Azure adf app"
  value       = azurerm_data_factory.adf.identity
}

output "shir_id" {
  description = "The ids of the self-hosted integration runtimes"
  value       = azurerm_data_factory_integration_runtime_self_hosted.shir[*].id
}

output "shir_name" {
  description = "The names of the self-hosted integration runtimes"
  value       = azurerm_data_factory_integration_runtime_self_hosted.shir[*].name
}

output "shir_primary_key" {
  description = "The primary authorization keys of the self-hosted integration runtimes"
  value       = azurerm_data_factory_integration_runtime_self_hosted.shir[*].primary_authorization_key
}
