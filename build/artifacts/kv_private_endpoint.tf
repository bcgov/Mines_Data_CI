# =============================================================================
# Add to build/artifacts/adf.tf
# =============================================================================

# Reference the existing ACI subnet where the tunnel container runs
data "azurerm_subnet" "aci" {
  name                 = "mines-fabric-aci-snet"
  virtual_network_name = "ef74b0-dev-vwan-spoke"
  resource_group_name  = "ef74b0-dev-networking"
}

###############################################################################
# Key Vault Private Endpoint
#
# Connects the KV to the ACI subnet so the tunnel container can reach it
# over the private network. No DNS zone group — policy blocks it.
# Name resolution via the private IP must be done manually or via existing
# hub DNS infrastructure.
###############################################################################

resource "azurerm_private_endpoint" "kv" {
  name                = "mines-fabric-kv01-pe"
  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"
  subnet_id           = data.azurerm_subnet.aci.id

  private_service_connection {
    name                           = "mines-fabric-kv01-psc"
    private_connection_resource_id = module.key_vault_adf.kv_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  # No private_dns_zone_group — policy blocks DNS zone creation.
  # The private endpoint gets a private IP in the ACI subnet.
  # To resolve privatelink.vaultcore.azure.net → private IP either:
  #   a) Use the hub DNS forwarder (if your Landing Zone has one)
  #   b) Set KEY_VAULT_URI env var to the private IP directly (quick workaround)
  #   c) Add a hosts entry inside the container: echo "<IP> mines-fabric-kv01.vault.azure.net" >> /etc/hosts



  depends_on = [
    module.key_vault_adf,
    module.subnets,
  ]
}

output "kv_private_endpoint_ip" {
  description = "Private IP of the Key Vault private endpoint. Use this to resolve KV from inside the ACI subnet when no private DNS zone is available."
  value       = azurerm_private_endpoint.kv.private_service_connection[0].private_ip_address
}