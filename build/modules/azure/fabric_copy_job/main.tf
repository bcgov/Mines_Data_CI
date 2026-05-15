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
  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = "1.10.0"
      configuration_aliases = [fabric.auth]
    }
  }
}
locals {
  activities = [
    for m in var.table_mappings : {
      properties = {
        source = {
          datasetSettings = {
            schema = var.source_schema
            table  = m.source_table
          }
        }
        destination = {
          datasetSettings = {
            schema = var.sink_schema
            table  = m.sink_table
          }
          tableOption   = var.table_option
          writeBehavior = "Append"
        }
        translator = {
          type = "TabularTranslator"
        }
        typeConversionSettings = {
          typeConversion = {
            allowDataTruncation  = true
            treatBooleanAsNumber = false
          }
        }
      }
    }
  ]
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
        source_connection_id = var.source_connection_id
        source_database      = var.source_database
        sink_workspace_id    = var.sink_workspace_id
        sink_warehouse_id    = var.sink_warehouse_id
        activities_json      = jsonencode(local.activities)
      }
    }
  }
}