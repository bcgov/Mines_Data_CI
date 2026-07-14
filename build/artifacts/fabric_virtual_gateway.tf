# =============================================================================
# build/artifacts/fabric_virtual_gateway.tf
#
# Adds a Fabric VNet Data Gateway with a dedicated delegated subnet allocated
# automatically by the subnet_allocator. The subnet is delegated to the
# Power Platform service so Fabric can inject the gateway resources into it.
#
# Note: Microsoft.PowerPlatform/vnetaccesslinks delegation is required for any
# subnet that hosts a Fabric VNet Data Gateway. The subnet cannot be shared
# with other workloads.
# =============================================================================

locals {
  # Network names default to the landing-zone pattern for the current
  # environment; override via VNET_NAME / VNET_RESOURCE_GROUP if needed.
  vnet_name      = coalesce(var.VNET_NAME, "${var.NETWORK_LICENSE_PLATE}-${var.ENVIRONMENT}-vwan-spoke")
  vnet_rg        = coalesce(var.VNET_RESOURCE_GROUP, "${var.NETWORK_LICENSE_PLATE}-${var.ENVIRONMENT}-networking")
  gw_subnet_name = "${var.PREFIX}-${var.PROJECT}-gw-snet-${var.ENVIRONMENT}01"
}

###############################################################################
# Subnet for the Fabric VNet Data Gateway
###############################################################################

module "fabric_gw_subnet" {
  source = "../modules/azure/subnet_allocator"

  vnet_name                = local.vnet_name
  vnet_resource_group_name = local.vnet_rg
  location                 = var.LOCATION

  subnets = [
    {
      name          = local.gw_subnet_name
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

  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"

  capacity_id                     = local.fabric_capacity_id
  inactivity_minutes_before_sleep = 30
  number_of_member_gateways       = 1

  # Points at the subnet created by fabric_gw_subnet above — previously this
  # was hardcoded to a different (dev) VNet/subnet than the one being created.
  virtual_network_azure_resource = {
    subscription_id      = var.ARM_SUBSCRIPTION_ID
    resource_group_name  = local.vnet_rg
    virtual_network_name = local.vnet_name
    subnet_name          = local.gw_subnet_name
  }

  role_assignments = [
    for id in var.GATEWAY_ADMINS : {
      principal_id   = id
      principal_type = "User"
      role           = "Admin"
    }
  ]

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
