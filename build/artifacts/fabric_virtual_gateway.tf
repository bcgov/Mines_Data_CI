# =============================================================================
# build/artifacts/fabric_data_gateway.tf
#
# Adds a Fabric VNet Data Gateway with a dedicated delegated subnet allocated
# automatically by the subnet_allocator. The subnet is delegated to the
# Power Platform service so Fabric can inject the gateway resources into it.
#
# Note: Microsoft.PowerPlatform/vnetaccesslinks delegation is required for any
# subnet that hosts a Fabric VNet Data Gateway. The subnet cannot be shared
# with other workloads.
# =============================================================================

###############################################################################
# Subnet for the Fabric VNet Data Gateway
###############################################################################
module "fabric_gw_subnet" {
  source = "../modules/azure/subnet_allocator"

  vnet_name                = "ef74b0-dev-vwan-spoke"
  vnet_resource_group_name = "ef74b0-dev-networking"
  location                 = "canadacentral"

  subnets = [
    {
      name          = "mines-fabric-gw-snet"
      prefix_length = 28
      delegation = {
        name         = "fabric-gw-delegation"
        service_name = "Microsoft.PowerPlatform/vnetaccesslinks"
        actions      = []
      }
      nsg_rules = [
        {
          name                       = "AllowFabricOutbound"
          priority                   = 200
          direction                  = "Outbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "AzureCloud"
        }
      ]
    }
  ]


}

###############################################################################
# Fabric VNet Data Gateway
###############################################################################

module "fabric_data_gateway_01" {
  source = "../modules/azure/fabric_virtual_gateway"

  providers = {
    fabric.auth = fabric.auth
  }

  prefix          = "mines"
  project         = "fabric"
  instance_number = "01"

  capacity_id                     = "198C68F4-8402-45B9-8010-BDE58A729DDF"
  inactivity_minutes_before_sleep = 30
  number_of_member_gateways       = 1

  virtual_network_azure_resource = {
    subscription_id      = var.ARM_SUBSCRIPTION_ID
    resource_group_name  = "ef74b0-dev-networking"
    virtual_network_name = "ef74b0-dev-vwan-spoke"
    subnet_name          = "mines-fabric-gw-snet"
  }

  timeouts = {
    create = "30m"
    read   = "5m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [module.fabric_gw_subnet]
}

###############################################################################
# Outputs
###############################################################################

output "fabric_data_gateway_id" {
  description = "ID of the Fabric VNet Data Gateway"
  value       = module.fabric_data_gateway_01.gateway_id
}

output "fabric_data_gateway_name" {
  description = "Display name of the gateway"
  value       = module.fabric_data_gateway_01.gateway_name
}
