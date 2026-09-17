# ─────────────────────────────────────────────────────────────────────────────
# Warehouse connection used by the control-table Lookup and every logging
# Script activity in the ingest pipelines.
#
# The connection is resolved from THIS environment's Terraform state:
# module.warehouse_mds_connection (fabric_wh_datasource.tf) creates
# "warehouse-<prefix>-<project>-<env>" against this environment's warehouse
# connection string and stores its GUID in terraform-<env>.tfstate.
#
# Previously this variable defaulted to the DEV connection GUID
# (60a2dcfb-…) and CI never overrode it, so test/prod pipelines connected to
# the dev workspace's SQL endpoint while asking for the <env> warehouse —
# "Login failed … database was not found" (18456, state 126).
#
# WAREHOUSE_CONNECTION_ID is an optional override (null by default). CI passes
# the GitHub Environment variable WAREHOUSE_CONNECTION_ID; when that is unset
# it arrives as "", which coalesce() skips.
# local.warehouse_connection_id uses coalesce(), which FAILS the plan/apply if
# both the override and the state lookup are empty — an empty connection can
# no longer reach a pipeline definition silently.
# ─────────────────────────────────────────────────────────────────────────────

variable "WAREHOUSE_CONNECTION_ID" {
  description = "Optional override for the warehouse connection GUID. Leave unset to use the connection Terraform manages for this environment."
  type        = string
  default     = null

  validation {
    condition     = var.WAREHOUSE_CONNECTION_ID == null || var.WAREHOUSE_CONNECTION_ID == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.WAREHOUSE_CONNECTION_ID))
    error_message = "WAREHOUSE_CONNECTION_ID must be empty/unset or a GUID."
  }
}

locals {
  warehouse_connection_id = coalesce(
    var.WAREHOUSE_CONNECTION_ID,
    module.warehouse_mds_connection.connection_id,
  )
}
