# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — PostgreSQL → Lakehouse Files (raw/table/yyyy/mm/dd/)
#
# Writes parquet files to the Lakehouse Files zone under:
#   raw/<table_name>/<yyyy>/<mm>/<dd>/<table_name>_<timestamp>.parquet
#
# No warehouse hop — raw landing zone only.
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
  activities = [
    for m in var.table_mappings : {
      name      = "Copy_${m.source_table}_to_raw"
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
          type             = "ParquetSink"
          storeSettings = {
            type                = "LakehouseWriteSettings"
            recursiveCompression = false
          }
          formatSettings = {
            type = "ParquetWriteSettings"
          }
          datasetSettings = {
            annotations = []
            linkedService = {
              name = var.lakehouse_name
              properties = {
                annotations = []
                type        = "Lakehouse"
                typeProperties = {
                  artifactId  = var.lakehouse_id
                  workspaceId = var.workspace_id
                  rootFolder  = "Files"
                }
              }
            }
            type   = "Parquet"
            schema = []
            typeProperties = {
              location = {
                type           = "LakehouseLocation"
                folderPath = {
                  value = "@concat('raw/${m.source_table}/', formatDateTime(utcNow(), 'yyyy'), '/', formatDateTime(utcNow(), 'MM'), '/', formatDateTime(utcNow(), 'dd'))"
                  type  = "Expression"
                }
              }
              compressionCodec = "snappy"
            }
          }
        }
        enableStaging = false
        # File name: <table>_<timestamp>.parquet
        fileNamePrefix = {
          value = "@concat('${m.source_table}_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'))"
          type  = "Expression"
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
