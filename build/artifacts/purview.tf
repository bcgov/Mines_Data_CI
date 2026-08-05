# =============================================================================
# build/artifacts/purview.tf
#
# Fabric tenant registration and scan in Microsoft Purview, plus the admin
# grants that go with them.
#
# A Microsoft Entra tenant may hold exactly one Purview account, and this tenant
# already has one — so by default this attaches to that account rather than
# creating another (which fails with 409 / error 35001). Set
# PURVIEW_ACCOUNT_NAME if the subscription holds more than one, or
# PURVIEW_CREATE_ACCOUNT = true only in a tenant that has none.
#
# Each environment registers its own data source and scan under the shared
# account, named from the same convention as the workspace
# (mcm-mdp-fabric01-dev), so dev/test/prod stay distinguishable in the Data Map.
#
# The same people who administer the Fabric workspace administer Purview —
# PURVIEW_ADMINS falls back to WORKSPACE_OWNERS so there is one list to
# maintain. Override PURVIEW_ADMINS per environment only if the two lists need
# to diverge.
# =============================================================================

locals {
  purview_admins = length(var.PURVIEW_ADMINS) > 0 ? var.PURVIEW_ADMINS : var.WORKSPACE_OWNERS

  # Only used to narrow the search for the existing account, or as the target
  # resource group when PURVIEW_CREATE_ACCOUNT is true. Null means "search the
  # whole subscription".
  purview_rg = var.PURVIEW_RESOURCE_GROUP_NAME
}

module "purview_01" {
  source = "../modules/azure/purview"

  env             = var.ENVIRONMENT
  prefix          = var.PREFIX
  project         = var.PROJECT
  instance_number = "01"
  location        = var.LOCATION

  create_account         = var.PURVIEW_CREATE_ACCOUNT
  purview_account_name   = var.PURVIEW_ACCOUNT_NAME
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
  description = "Name of the Purview account this configuration registers the Fabric scan against"
  value       = module.purview_01.purview_name
}

output "purview_created_here" {
  description = "False when attached to the pre-existing tenant-level account, true when this configuration owns it"
  value       = module.purview_01.purview_created_here
}

output "purview_scan_endpoint" {
  description = "Scanning data-plane endpoint of the Purview account"
  value       = module.purview_01.purview_scan_endpoint
}

output "purview_identity_principal_id" {
  description = "Object ID of the Purview managed identity. Add this to the Entra security group allowed to use the Fabric read-only admin APIs."
  value       = module.purview_01.purview_identity_principal_id
}
