# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — PostgreSQL or Oracle → Fabric Warehouse
#
# Creates a Fabric Data Pipeline item using the Copy activity schema.
# Source connection is a Fabric connection referenced by ID.
# Sink is a Fabric Warehouse referenced by workspace/artifact IDs.
#
# Trigger: on-demand only. No schedule attached.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = ">= 1.5"
      configuration_aliases = [fabric.auth]
    }
  }
}

locals {
  # Build one Copy activity per table mapping.
  # Sink structure confirmed from Fabric portal JSON export — uses inline
  # linkedService block inside datasetSettings, not externalReferences.
  activities = [
    for m in var.table_mappings : {
      name      = "Copy_${m.source_table}_to_${m.sink_table}"
      type      = "Copy"
      dependsOn = []
      policy = {
        timeout                = var.activity_timeout
        retry                  = var.activity_retry
        retryIntervalInSeconds = 30
        secureOutput           = false
        secureInput            = false
      }
      typeProperties = {
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"
          datasetSettings = {
            annotations = []
            type        = "PostgreSqlTable"
            schema      = []
            typeProperties = {
              schema = var.source_schema
              table  = m.source_table
            }
            externalReferences = {
              connection = var.source_connection_id
            }
          }
        }
        sink = {
          type             = "DataWarehouseSink"
          allowCopyCommand = true
          writeBehavior    = "Insert"
          tableOption      = var.table_option
          datasetSettings = {
            annotations = []
            linkedService = {
              name = var.sink_warehouse_name
              properties = {
                annotations = []
                type        = "DataWarehouse"
                typeProperties = {
                  endpoint    = var.sink_endpoint
                  artifactId  = var.sink_warehouse_id
                  workspaceId = var.sink_workspace_id
                }
              }
            }
            type   = "DataWarehouseTable"
            schema = []
            typeProperties = {
              schema = var.sink_schema
              table  = m.sink_table
            }
          }
        }
        enableStaging = false
        translator = {
          type = "TabularTranslator"
          typeConversion = true
          typeConversionSettings = {
            allowDataTruncation  = var.allow_data_truncation
            treatBooleanAsNumber = false
          }
        }
      }
    }
  ]
}

resource "fabric_data_pipeline" "this" {
  provider = fabric.auth

  display_name = var.display_name
  description  = var.description
  workspace_id = var.workspace_id
  format       = "Default"

  definition_update_enabled = true

  definition = {
    "pipeline-content.json" = {
      source = "${path.module}/pipeline-content.json.tmpl"
      tokens = {
        display_name    = var.display_name
        activities_json = jsonencode(local.activities)
      }
    }
  }
}
