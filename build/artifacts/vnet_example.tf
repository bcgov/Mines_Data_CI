module "vnet" {
  source = "../modules/azure/vnet"

  prefix          = "nr"
  suffix          = "tools"
  project         = "fabric"
  env             = "dev"
  instance_number = "01"

  resource_group_name = "rg-nr-tools-dev-01"
  location            = "canadacentral"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    snet-app = {
      address_prefixes = ["10.0.1.0/24"]
    }
    snet-pe = {
      address_prefixes                  = ["10.0.2.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
  }
}