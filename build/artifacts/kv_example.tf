module "key_vault" {
  source                        = "../modules/azure/key_vaults"
  prefix                        = "nr"
  suffix                        = "tools"
  project                       = "fabric"
  env                           = var.ENVIRONMENT
  Instance_Number               = "02"
  resource_group_name           = "nrfabric-rg1"
  location                      = "canadacentral"
  public_network_access_enabled = false
  private_endpoint_enabled      = true
  private_endpoint_subnet_id    = "/subscriptions/ffc5e617-7f2d-4ddb-8b57-33fc43989a8c/resourceGroups/b9cee3-tools-networking/providers/Microsoft.Network/virtualNetworks/b9cee3-tools-vwan-spoke/subnets/privateendpoints-subnet"
  private_dns_zone_ids          = []
  additional_access_policies = [

    {
      object_id            = "6f523291-c78a-4e05-aae1-de6b07a07a11"
      role_definition_name = "Key Vault Secrets Officer" # manage secrets
    },
    {
      object_id            = "6f523291-c78a-4e05-aae1-de6b07a07a11"
      role_definition_name = "Key Vault Crypto Officer"
    }
  ]
}