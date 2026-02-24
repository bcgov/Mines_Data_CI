module "key_vault" {
  source = "./modules/key_vaults"

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
depends_on = [ module.vnet ]
}