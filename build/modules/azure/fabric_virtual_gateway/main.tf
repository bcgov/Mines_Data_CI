terraform {
  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = "1.6.0"
      configuration_aliases = [fabric.auth]
    }
  }
}

locals {
  gateway_name = substr(
    replace(
      var.gateway_name != null ? var.gateway_name : "${var.prefix}-${var.project}-fabricgw${var.instance_number}",
      " ",
      ""
    ),
    0,
    200
  )
}

resource "fabric_gateway" "this" {
  provider                        = fabric.auth
  type                            = "VirtualNetwork"
  display_name                    = local.gateway_name
  capacity_id                     = var.capacity_id
  inactivity_minutes_before_sleep = var.inactivity_minutes_before_sleep
  number_of_member_gateways       = var.number_of_member_gateways

  virtual_network_azure_resource = {
    resource_group_name  = var.virtual_network_azure_resource.resource_group_name
    virtual_network_name = var.virtual_network_azure_resource.virtual_network_name
    subnet_name          = var.virtual_network_azure_resource.subnet_name
    subscription_id      = var.virtual_network_azure_resource.subscription_id
  }

  timeouts = {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
