# modules/resource-group/main.tf
data "azurerm_client_config" "current" {}

locals {
  name = substr(replace(var.custom_rg_name == null ? "${var.prefix}-${var.project}-${var.suffix}${var.Instance_Number}" : var.custom_rg_name, " ", ""), 0, 24)
}

resource "azurerm_resource_group" "rg" {
  name     = local.name
  location = var.location
  tags     = var.tags
}

data "azurerm_resources" "existing_resource_groups" {
  type = "Microsoft.Resources/resourceGroups"
}