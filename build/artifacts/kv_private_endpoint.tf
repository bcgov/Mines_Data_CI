# =============================================================================
# build/artifacts/kv_private_endpoint.tf
# =============================================================================

###############################################################################
# Key Vault Private Endpoint
###############################################################################

resource "azurerm_private_endpoint" "kv" {
  name                = "mines-fabric-kv01-pe"
  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"
  subnet_id           = module.subnets.subnet_ids["mines-fabric-pe-snet"]

  private_service_connection {
    name                           = "mines-fabric-kv01-psc"
    private_connection_resource_id = module.key_vault_adf.kv_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  # No private_dns_zone_group — policy blocks DNS zone creation.

  depends_on = [
    module.key_vault_adf,
    module.subnets,
  ]
}

output "kv_private_endpoint_ip" {
  description = "Private IP of the Key Vault private endpoint."
  value       = azurerm_private_endpoint.kv.private_service_connection[0].private_ip_address
}

###############################################################################
# Inject hosts entry into tunnel container
#
# Runs after the PE is created. Writes the KV private IP to /etc/hosts
# inside the running tunnel container so vault.azure.net resolves via
# the private endpoint without needing a DNS zone.
#
# Re-runs whenever the private IP changes (e.g. PE recreated).
###############################################################################

resource "terraform_data" "kv_hosts_entry" {
  input = azurerm_private_endpoint.kv.private_service_connection[0].private_ip_address

  provisioner "local-exec" {
    command = join(" ", [
      "az container exec",
      "--subscription 53205a1b-0f8d-459e-a424-65f1b39ec648",
      "--resource-group ${module.resource_group_adf.rg_name}",
      "--name mines-fabric-tunnel01",
      "--container-name vscode-tunnel",
      "--exec-command",
      "\"sh -c 'echo ${azurerm_private_endpoint.kv.private_service_connection[0].private_ip_address} mines-fabric-kv01.vault.azure.net >> /etc/hosts && echo hosts entry added'\""
    ])
  }

  depends_on = [
    azurerm_private_endpoint.kv,
    module.vscode_tunnel,
  ]
}
