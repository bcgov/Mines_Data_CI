output "fabric_resource_group_id" {
  value = azurerm_resource_group.this.id
}

output "fabric_resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "fabric_capacity_id" {
  value = azurerm_fabric_capacity.this.id
}

output "fabric_capacity_name" {
  value = azurerm_fabric_capacity.this.name
}
