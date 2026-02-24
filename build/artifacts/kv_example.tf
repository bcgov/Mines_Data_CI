module "key_vault" {
  source = "../modules/azure/key_vaults"

  prefix              = "nr"
  suffix              = "tools"
  project             = "fabric"
  env                 = "dev"
  Instance_Number     = "01"
  resource_group_name = "rg-nr-tools-dev-01"
  location            = "canadacentral"

  public_network_access_enabled = false
  private_endpoint_enabled      = true
  private_endpoint_subnet_id    = module.vnet.subnet_ids["snet-pe"]
  private_dns_zone_ids          = [module.vnet.kv_private_dns_zone_id]
  virtual_network_subnet_ids    = [module.vnet.subnet_ids["snet-app"]]

  additional_access_policies = [
    {
      object_id = "6f523291-c78a-4e05-aae1-de6b07a07a11"
      key_permissions = [
        "Create",
        "Decrypt",
        "Encrypt",
        "Get",
        "List",
        "Rotate",
        "GetRotationPolicy",
        "SetRotationPolicy",
      ]
      secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
        "Recover",
        "Backup",
        "Restore",
      ]
    }
  ]

  depends_on = [module.vnet]
}