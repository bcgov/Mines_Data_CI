# =============================================================================
# build/artifacts/fabric_capacities.tf
#
# Capacity ID resolution. Set FABRIC_CAPACITY_NAME (GitHub Environment
# variable per branch) to look the capacity up by display name — no GUID
# needed. If it is empty, the FABRIC_CAPACITY_ID fallback from variables.tf
# is used instead.
# =============================================================================

data "fabric_capacity" "by_name" {
  count    = trimspace(var.FABRIC_CAPACITY_NAME) != "" ? 1 : 0
  provider = fabric.auth

  display_name = var.FABRIC_CAPACITY_NAME
}

locals {
  fabric_capacity_id = (
    trimspace(var.FABRIC_CAPACITY_NAME) != ""
    ? data.fabric_capacity.by_name[0].id
    : var.FABRIC_CAPACITY_ID
  )
}

# Capacity provisioning stays disabled — capacities are managed outside this
# repo. Kept for reference.
# module "fabric_capacity" {
#   source          = "../modules/azure/fabric_rm_capacities"
#   prefix          = var.PREFIX
#   suffix          = var.ENVIRONMENT
#   project         = var.PROJECT
#   Instance_Number = "01"
#   location        = var.LOCATION
#   Owners          = var.WORKSPACE_OWNERS
# }
