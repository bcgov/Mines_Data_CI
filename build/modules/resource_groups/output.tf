# modules/resource-group/outputs.tf

output "rg_id" {
  description = "The ID of the created Azure Resource Group"
  value       = azurerm_resource_group.rg.id
}

output "rg_name" {
  description = "The name of the created Azure Resource Group"
  value       = azurerm_resource_group.rg.name
}


output "existing_resource_group_count" {
  value = length(data.azurerm_resources.existing_resource_groups.resources)
}