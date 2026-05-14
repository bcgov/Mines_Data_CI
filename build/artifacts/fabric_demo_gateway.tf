data "azurerm_network_security_group" "fabric_gateway" {
  name                = "quickstart-azure-containers-tools-apim-nsg"
  resource_group_name = "b9cee3-tools-networking"
}
resource "azapi_resource" "fabric_gateway_subnet" {
  type      = "Microsoft.Network/virtualNetworks/subnets@2023-04-01"
  name      = "snet-fabric-gateway"
  parent_id = "/subscriptions/ffc5e617-7f2d-4ddb-8b57-33fc43989a8c/resourceGroups/b9cee3-tools-networking/providers/Microsoft.Network/virtualNetworks/b9cee3-tools-vwan-spoke"

  body = {
    properties = {
      addressPrefix = "10.46.10.144/28"
      networkSecurityGroup = {
        id = data.azurerm_network_security_group.fabric_gateway.id
      }
      delegations = [
        {
          name = "fabric-delegation"
          properties = {
            serviceName = "Microsoft.PowerPlatform/vnetaccesslinks"
          }
        }
      ]
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
  depends_on = [azapi_resource.fabric_gateway_subnet]
}


