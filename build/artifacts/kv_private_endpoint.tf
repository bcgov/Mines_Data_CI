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
