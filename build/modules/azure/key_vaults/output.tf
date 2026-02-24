output "kv_id" {
  description = "The ID of the created Azure Key Vault"
  value       = azurerm_key_vault.kv.id
}

output "kv_name" {
  description = "The name of the created Azure Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "kv_dns_uri" {
  description = "URI for KV required to tie resources to several objects"
  value       = azurerm_key_vault.kv.vault_uri
}