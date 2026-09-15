# ─────────────────────────────────────────────────────────────────────────────
# Warehouse connection used by the control-table Lookup and every logging
# Script activity in the ingest pipelines.
#
# Pinned to an explicit GUID instead of module.warehouse_mds_connection, whose
# display-name lookup returns "" on a miss and silently deployed an empty
# connection reference (InvalidExternalReferenceConnection at run time).
#
# Per environment: dev is the default below. test and prod branches must
# override this with their own connection GUID — either by editing the default
# on that branch or by setting TF_VAR_WAREHOUSE_CONNECTION_ID in CI.
#
# Find the GUID in Fabric: Manage connections and gateways → select the
# warehouse connection → the ID is in the URL and on the settings pane.
# ─────────────────────────────────────────────────────────────────────────────

variable "WAREHOUSE_CONNECTION_ID" {
  description = "Fabric connection GUID for the warehouse hosting app.pipeline_control and app.pipeline_log."
  type        = string
  default     = "60a2dcfb-8aae-4e97-ba29-caee2af9f84a"

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.WAREHOUSE_CONNECTION_ID))
    error_message = "WAREHOUSE_CONNECTION_ID must be a GUID. An empty or malformed value is what caused InvalidExternalReferenceConnection previously."
  }
}
