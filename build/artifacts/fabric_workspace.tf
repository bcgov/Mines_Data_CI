# artifacts/fabric_workspace.tf
# imports.tf — delete after one successful apply
locals {
  existing_ws_admins = [
    "d7a27896-3a20-4678-b8c6-3c7cebdbc4ec",
    "71a5bb67-14d7-40fe-8f3e-47120f2e32d3",
  ]
}

import {
  for_each = toset(local.existing_ws_admins)
  to       = module.fabric_workspace_01.fabric_workspace_role_assignment.admins[each.key]
  id       = "e397b5cc-924d-40a5-b101-f6efb41a5423/${each.key}"
}

module "fabric_workspace_01" {
  source = "../modules/azure/fabric_workspace"
  providers = {
    fabric.auth = fabric.auth
  }
  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "00"
  capacity_id     = local.fabric_capacity_id
  owners          = var.WORKSPACE_OWNERS
  identity_type   = "SystemAssigned"
}

