output "subnet_ids" {
  description = "Map of subnet name → subnet resource ID."
  value       = { for k, v in azapi_resource.subnet : k => v.id }
}

output "subnet_cidrs" {
  description = "Map of subnet name → allocated CIDR block."
  value       = { for k, v in data.external.cidr : k => v.result["cidr"] }
}

output "subnet_names" {
  description = "Map of subnet name → subnet resource name."
  value       = { for k, v in azapi_resource.subnet : k => v.name }
}

output "nsg_ids" {
  description = "Map of subnet name → NSG resource ID."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}

output "nsg_names" {
  description = "Map of subnet name → NSG resource name."
  value       = { for k, v in azurerm_network_security_group.this : k => v.name }
}

output "vnet_name" {
  description = "Name of the VNet that was targeted."
  value       = data.azurerm_virtual_network.vnet.name
}

output "vnet_address_space" {
  description = "Address space of the targeted VNet."
  value       = data.azurerm_virtual_network.vnet.address_space
}
