# =============================================================================
# build/artifacts/purview.tf
#
# Microsoft Purview account for the data platform, plus the Fabric tenant
# registration and scan that keep the catalog in sync with the workspace
# created in fabric_workspace.tf.
#
# The same people who administer the Fabric workspace administer Purview —
# PURVIEW_ADMINS falls back to WORKSPACE_OWNERS so there is one list to
# maintain. Override PURVIEW_ADMINS per environment only if the two lists need
# to diverge.
# =============================================================================

locals {
  purview_admins = length(var.PURVIEW_ADMINS) > 0 ? var.PURVIEW_ADMINS : var.WORKSPACE_OWNERS

  # Landing-zone application resource group for the current environment, unless
  # overridden. Follows the same derivation as the networking names in
  # fabric_virtual_gateway.tf.
  purview_rg = coalesce(var.PURVIEW_RESOURCE_GROUP_NAME, "${var.NETWORK_LICENSE_PLATE}-${var.ENVIRONMENT}")
}

module "purview_01" {
  source = "../modules/azure/purview"

  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"
  location        = var.LOCATION

  resource_group_name    = local.purview_rg
  public_network_enabled = var.PURVIEW_PUBLIC_NETWORK_ENABLED

  # Root Collection Admin — full data-plane admin on the account.
  admins = local.purview_admins

  # Fabric tenant registration + scan, scoped to the workspace this repo owns.
  enable_fabric_scan = var.PURVIEW_SCAN_ENABLED
  fabric_tenant_id   = var.ARM_TENANT_ID
  scan_workspace_ids = var.PURVIEW_SCAN_SCOPE_TO_WORKSPACE ? [module.fabric_workspace_01.workspace_id] : []
  run_scan_on_apply  = var.PURVIEW_RUN_SCAN_ON_APPLY

  scan_recurrence = {
    frequency  = "Week"
    interval   = 1
    start_time = "2026-01-05T06:00:00Z"
    hours      = [6]
    minutes    = [0]
    week_days  = ["Sunday"]
  }
}

###############################################################################
# Outputs
###############################################################################

output "purview_name" {
  description = "Name of the Purview account"
  value       = module.purview_01.purview_name
}

output "purview_scan_endpoint" {
  description = "Scanning data-plane endpoint of the Purview account"
  value       = module.purview_01.purview_scan_endpoint
}

output "purview_identity_principal_id" {
  description = "Object ID of the Purview managed identity. Add this to the Entra security group allowed to use the Fabric read-only admin APIs."
  value       = module.purview_01.purview_identity_principal_id
}
