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
  # Build one Copy activity per table mapping
  activities = [
    for m in var.table_mappings : {
      name       = "Copy_${m.source_table}_to_${m.sink_table}"
      type       = "Copy"
      dependsOn  = []
      policy = {
        timeout             = var.activity_timeout
        retry               = var.activity_retry
        retryIntervalInSeconds = 30
        secureOutput        = false
        secureInput         = false
      }
      typeProperties = {
        source = {
          type  = "PostgreSqlSource"
          query = "SELECT * FROM ${var.source_schema}.${m.source_table}"
        }
        sink = {
          type              = "WarehouseSink"
          writeBehavior     = var.write_behavior
          tableOption       = var.table_option
          preCopyScript     = ""
          allowPolyBase     = false
        }
        enableStaging = var.enable_staging
        translator = {
          type = "TabularTranslator"
          typeConversion = true
          typeConversionSettings = {
            allowDataTruncation  = var.allow_data_truncation
            treatBooleanAsNumber = false
          }
        }
      }
      inputs = [
        {
          referenceName = "ds_postgresql_source"
          type          = "DatasetReference"
          parameters = {
            source_table  = m.source_table
          }
        }
      ]
      outputs = [
        {
          referenceName = "ds_warehouse_sink"
          type          = "DatasetReference"
          parameters = {
            sink_table = m.sink_table
          }
        }
      ]
    }
  ]

  pipeline_content = jsonencode({
    name = var.display_name
    properties = {
      activities = local.activities
      parameters = {}
      variables  = {}
      annotations = []
    }
    connections = {
      # Source PostgreSQL connection
      ds_postgresql_source = {
        connectionId = var.source_connection_id
        connectionType = "linkedService"
        type = "ConnectionReference"
        properties = {
          type = "PostgreSql"
          typeProperties = {
            database = var.source_database
            schema   = var.source_schema
          }
        }
      }
      # Sink Fabric Warehouse connection
      ds_warehouse_sink = {
        connectionType = "linkedService"
        type = "ConnectionReference"
        properties = {
          type = "Warehouse"
          typeProperties = {
            workspaceId = var.sink_workspace_id
            artifactId  = var.sink_warehouse_id
            schema      = var.sink_schema
          }
        }
      }
    }
  })
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
        display_name         = var.display_name
        source_connection_id = var.source_connection_id
        source_database      = var.source_database
        source_schema        = var.source_schema
        sink_workspace_id    = var.sink_workspace_id
        sink_warehouse_id    = var.sink_warehouse_id
        sink_schema          = var.sink_schema
        write_behavior       = var.write_behavior
        table_option         = var.table_option
        allow_data_truncation = tostring(var.allow_data_truncation)
        activity_timeout     = var.activity_timeout
        activity_retry       = tostring(var.activity_retry)
        enable_staging       = tostring(var.enable_staging)
        activities_json      = jsonencode(local.activities)
      }
    }
  }
}
