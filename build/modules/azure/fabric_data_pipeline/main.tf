
# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — Control Table Driven with Full Logging
#
# Flow per table (inside ForEach):
#   1. Log_Start       → INSERT into app.pipeline_log (status = RUNNING)
#   2. Copy_to_Raw     → PostgreSQL → Lakehouse Files raw/entity/yyyy/mm/dd/
#   3. Log_Success     → UPDATE app.pipeline_log (status = SUCCEEDED)
#                      → UPDATE app.pipeline_control
#   4. Log_Failure     → UPDATE app.pipeline_log (status = FAILED)
#                      → UPDATE app.pipeline_control
#
# Output path:
#   raw/<target_table>/yyyy/mm/dd/<target_table>_<timestamp>.parquet
#
# IMPORTANT:
#   source_entity is used ONLY for PostgreSQL source references
#   target_table  is used ONLY for filesystem-safe output naming
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

  # ───────────────────────────────────────────────────────────────────────────
  # Shared Warehouse Linked Service
  # ───────────────────────────────────────────────────────────────────────────
  warehouse_linked_service = {
    name = var.sink_warehouse_name

    properties = {
      annotations = []
      type        = "DataWarehouse"

      typeProperties = {
        endpoint    = var.sink_endpoint
        artifactId  = var.sink_warehouse_id
        workspaceId = var.workspace_id
      }
    }
  }

  # ───────────────────────────────────────────────────────────────────────────
  # Activities executed INSIDE foreach loop
  # ───────────────────────────────────────────────────────────────────────────
  foreach_activities = [

    # ── 1. Log_Start ────────────────────────────────────────────────────────
    {
      name      = "Log_Start"
      type      = "Script"
      dependsOn = []

      policy = {
        timeout                = "0.00:05:00"
        retry                  = 0
        retryIntervalInSeconds = 30
        secureOutput           = false
        secureInput            = false
      }

      typeProperties = {
        scripts = [
          {
            type = "NonQuery"

            text = {
              value = "@concat('INSERT INTO [app].[pipeline_log] ([run_id],[activity_run_id],[pipeline_name],[source_entity],[target_schema],[target_table],[status],[from_date],[to_date],[watermark_start],[start_time],[environment],[triggered_by],[created_date]) VALUES (''', pipeline().RunId, ''',''', activity('Log_Start').ActivityRunId, ''',''', pipeline().parameters.pipeline_name, ''',''', item().source_entity, ''',''', item().target_schema, ''',''', item().target_table, ''',''RUNNING'',', if(empty(string(item().from_date)), 'NULL', concat('''', string(item().from_date), '''')), ',', if(empty(string(item().to_date)), 'NULL', concat('''', string(item().to_date), '''')), ',', if(empty(item().last_watermark), 'NULL', concat('''', item().last_watermark, '''')), ',''', utcNow(), ''',''DEV'',''', pipeline().TriggerName, ''',''', utcNow(), ''')')"
              type  = "Expression"
            }
          }
        ]

        datasetSettings = {
          annotations   = []
          linkedService = local.warehouse_linked_service
          type          = "DataWarehouseTable"
          schema        = []

          typeProperties = {
            schema = "app"
            table  = "pipeline_log"
          }
        }
      }
    },

    # ── 2. Copy PostgreSQL → Lakehouse Raw ─────────────────────────────────
    {
      name = "Copy_to_Raw"
      type = "Copy"

      dependsOn = [
        {
          activity             = "Log_Start"
          dependencyConditions = ["Succeeded"]
        }
      ]

      policy = {
        timeout                = var.activity_timeout
        retry                  = var.activity_retry
        retryIntervalInSeconds = 30
        secureOutput           = false
        secureInput            = false
      }

      typeProperties = {

        # ── PostgreSQL Source ───────────────────────────────────────────────
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"

          query = {
            value = "@if(empty(item().source_query_template), concat('SELECT * FROM ', item().target_schema, '.', item().source_entity), item().source_query_template)"
            type  = "Expression"
          }

          datasetSettings = {
            annotations = []
            type        = "PostgreSqlTable"
            schema      = []

            typeProperties = {
              schema = {
                value = "@item().target_schema"
                type  = "Expression"
              }

              table = {
                value = "@item().source_entity"
                type  = "Expression"
              }
            }

            externalReferences = {
              connection = var.source_connection_id
            }
          }
        }

        # ── Lakehouse Sink ──────────────────────────────────────────────────
        sink = {
          type = "ParquetSink"

          storeSettings = {
            type                 = "LakehouseWriteSettings"
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

              # ── SAFE OUTPUT LOCATION ──────────────────────────────────────
              # Uses target_table instead of source_entity
              # Prevents quoted SQL identifiers from appearing in filenames
              location = {
                type = "LakehouseLocation"

                folderPath = {
                  value = "@concat('raw/', item().target_table, '/', formatDateTime(utcNow(), 'yyyy'), '/', formatDateTime(utcNow(), 'MM'), '/', formatDateTime(utcNow(), 'dd'))"
                  type  = "Expression"
                }

                fileName = {
                  value = "@concat(item().target_table, '_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.parquet')"
                  type  = "Expression"
                }
              }

              compressionCodec = "snappy"
            }
          }
        }

        enableStaging = false
      }
    },

    # ── 3. Log Success ──────────────────────────────────────────────────────
    {
      name = "Log_Success"
      type = "Script"

      dependsOn = [
        {
          activity             = "Copy_to_Raw"
          dependencyConditions = ["Succeeded"]
        }
      ]

      policy = {
        timeout                = "0.00:05:00"
        retry                  = 0
        retryIntervalInSeconds = 30
        secureOutput           = false
        secureInput            = false
      }

      typeProperties = {
        scripts = [

          # Update pipeline_log
          {
            type = "NonQuery"

            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(activity('Copy_to_Raw').output.rowsRead), ', [rows_written]=', string(activity('Copy_to_Raw').output.rowsCopied), ', [end_time]=''', utcNow(), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },

          # Update pipeline_control
          {
            type = "NonQuery"

            text = {
              value = "@concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [last_watermark]=', if(empty(item().watermark_column), 'NULL', concat('''', utcNow(), '''')), ', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id))"
              type  = "Expression"
            }
          }
        ]

        datasetSettings = {
          annotations   = []
          linkedService = local.warehouse_linked_service
          type          = "DataWarehouseTable"
          schema        = []

          typeProperties = {
            schema = "app"
            table  = "pipeline_log"
          }
        }
      }
    },

    # ── 4. Log Failure ──────────────────────────────────────────────────────
    {
      name = "Log_Failure"
      type = "Script"

      dependsOn = [
        {
          activity             = "Copy_to_Raw"
          dependencyConditions = ["Failed"]
        }
      ]

      policy = {
        timeout                = "0.00:05:00"
        retry                  = 0
        retryIntervalInSeconds = 30
        secureOutput           = false
        secureInput            = false
      }

      typeProperties = {
        scripts = [

          # Update pipeline_log
          {
            type = "NonQuery"

            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(activity('Copy_to_Raw').output.errors[0].Message, '''', ''''''), ''', [error_code]=''', activity('Copy_to_Raw').output.errors[0].Code, ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },

          # Update pipeline_control
          {
            type = "NonQuery"

            text = {
              value = "@concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''FAILED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id))"
              type  = "Expression"
            }
          }
        ]

        datasetSettings = {
          annotations   = []
          linkedService = local.warehouse_linked_service
          type          = "DataWarehouseTable"
          schema        = []

          typeProperties = {
            schema = "app"
            table  = "pipeline_log"
          }
        }
      }
    }
  ]

  # ───────────────────────────────────────────────────────────────────────────
  # OUTER PIPELINE ACTIVITIES
  # ───────────────────────────────────────────────────────────────────────────
  activities = [

    # ── Lookup Control Table ────────────────────────────────────────────────
    {
      name      = "Lookup_ControlTable"
      type      = "Lookup"
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
          type            = "DataWarehouseSource"
          partitionOption = "None"

          query = {
            value = "@concat('SELECT control_id, pipeline_name, source_system, source_entity, target_schema, target_table, source_query_template, watermark_column, last_watermark, load_type, priority, from_date, to_date FROM [app].[pipeline_control] WHERE [pipeline_name] = ''', pipeline().parameters.pipeline_name, ''' AND [is_active] = 1 ORDER BY [priority] ASC')"
            type  = "Expression"
          }
        }

        datasetSettings = {
          annotations   = []
          linkedService = local.warehouse_linked_service
          type          = "DataWarehouseTable"
          schema        = []

          typeProperties = {
            schema = "app"
            table  = "pipeline_control"
          }
        }

        firstRowOnly = false
      }
    },

    # ── ForEach Control Rows ────────────────────────────────────────────────
    {
      name = "ForEach_ControlRows"
      type = "ForEach"

      dependsOn = [
        {
          activity             = "Lookup_ControlTable"
          dependencyConditions = ["Succeeded"]
        }
      ]

      typeProperties = {
        isSequential = false
        batchCount   = var.parallel_copies

        items = {
          value = "@activity('Lookup_ControlTable').output.value"
          type  = "Expression"
        }

        activities = local.foreach_activities
      }
    }
  ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Fabric Pipeline Resource
# ─────────────────────────────────────────────────────────────────────────────
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
        display_name        = var.display_name
        activities_json     = jsonencode(local.activities)
        pipeline_name_param = var.pipeline_name_param_default
      }
    }
  }
}

