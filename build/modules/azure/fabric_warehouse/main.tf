terraform {
  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = "1.10.0"
      configuration_aliases = [fabric.auth]
    }
  }
}

locals {
  fabric_warehouse = var.fabric_warehouse != null ? var.fabric_warehouse : "${var.prefix}-${var.project}-fabwh${var.instance_number}${var.env != "" ? "-${var.env}" : ""}"
}


resource "fabric_warehouse" "this_warehouse" {
  provider     = fabric.auth
  display_name = local.fabric_warehouse
  workspace_id = var.workspace_id
}

