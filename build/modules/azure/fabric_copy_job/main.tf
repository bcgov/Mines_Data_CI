# ─────────────────────────────────────────────────────────────────────────────
# Fabric Copy Job — Generic source → Fabric Warehouse
#
# Creates a Fabric Copy Job item in the target workspace.
# Source can be any connection (PostgreSQL or Oracle in this stack).
# Sink is a Fabric Warehouse in the same or another workspace.
#
# Trigger: on-demand only. Run via Fabric Portal, Fabric CLI, or REST API.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 1.5"
    }
  }
}

resource "fabric_copy_job" "this" {
  display_name = var.display_name
  description  = var.description
  workspace_id = var.workspace_id
  format       = "Default"

  definition_update_enabled = true

  definition = {
    "copyjob-content.json" = {
      source = "${path.module}/copyjob-content.json.tmpl"
      tokens = {
        source_type          = var.source_type
        source_connection_id = var.source_connection_id
        source_database      = var.source_database
        source_schema        = var.source_schema
        sink_workspace_id    = var.sink_workspace_id
        sink_warehouse_id    = var.sink_warehouse_id
        sink_schema          = var.sink_schema
        table_mappings_json  = jsonencode(var.table_mappings)
        table_option         = var.table_option
      }
    }
  }
}
