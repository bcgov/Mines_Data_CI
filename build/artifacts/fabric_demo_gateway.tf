resource "azurerm_subnet" "fabric_gateway" {
  name                 = "snet-fabric-gateway"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.46.10.144/24"]

  delegation {
    name = "fabric-delegation"
    service_delegation {
      name    = "Microsoft.PowerPlatform/vnetaccesslinks"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


module "fabric_gateway_minimal" {
  source = "../modules/azure/fabric_virtual_gateway"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix      = "nr"
  project     = "fabric"
  capacity_id = "77e89824-a07e-42b8-b47f-2c68c13fb559"

  virtual_network_azure_resource = {
    subscription_id      = "ffc5e617-7f2d-4ddb-8b57-33fc43989a8c"
    resource_group_name  = "b9cee3-tools-networking"
    virtual_network_name = "b9cee3-tools-vwan-spoke"
    subnet_name          = "snet-fabric-gateway"
  }

  # Gateway behaviour
  inactivity_minutes_before_sleep = 60
  number_of_member_gateways       = 3

  # Timeouts
  timeouts = {
    create = "45m"
    read   = "5m"
    update = "45m"
    delete = "30m"
  }
  depends_on = [ resource.azurerm_subnet.fabric_gateway ]
}


