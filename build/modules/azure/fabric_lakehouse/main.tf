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
  lakehouse_name = substr(
    replace(
      replace(
        var.lakehouse_name != null ? var.lakehouse_name : "${var.prefix}-${var.project}-lh${var.instance_number}",
        " ",
        ""
      ),
      "-",
      "_"
    ),
    0,
    30
  )
}

resource "fabric_lakehouse" "this" {
  provider     = fabric.auth
  display_name = local.lakehouse_name
  description  = var.description
  workspace_id = var.workspace_id

  # enable_schemas forces recreation if changed after creation — set once and leave
  configuration = var.enable_schemas ? {
    enable_schemas = true
  } : null

  timeouts = {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
