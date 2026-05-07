output "container_group_id" {
  description = "Resource ID of the VS Code tunnel container group."
  value       = azurerm_container_group.tunnel.id
}

output "container_group_name" {
  description = "Name of the VS Code tunnel container group."
  value       = azurerm_container_group.tunnel.name
}

output "ip_address" {
  description = "Private IP address of the container group inside the VNet."
  value       = azurerm_container_group.tunnel.ip_address
}

output "tunnel_url" {
  description = "VS Code web URL to connect to the tunnel (available after first-time GitHub auth)."
  value       = "https://vscode.dev/tunnel/${var.tunnel_name}"
}

output "get_auth_code_command" {
  description = "Run this command to get the GitHub device code on first start."
  value       = "az container logs --subscription 53205a1b-0f8d-459e-a424-65f1b39ec648 --resource-group ${var.resource_group_name} --name ${azurerm_container_group.tunnel.name} --container-name vscode-tunnel"
}
