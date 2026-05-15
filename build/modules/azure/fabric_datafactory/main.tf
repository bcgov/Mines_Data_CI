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
  pipeline_name = substr(
    replace(
      var.pipeline_name != null ? var.pipeline_name : "${var.prefix}-${var.project}-pl${var.instance_number}",
      " ",
      ""
    ),
    0,
    30
  )
}

resource "fabric_data_pipeline" "this" {
  provider     = fabric.auth
  display_name = local.pipeline_name
  description  = var.description
  workspace_id = var.workspace_id

  timeouts = {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
