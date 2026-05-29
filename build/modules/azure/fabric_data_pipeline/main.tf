# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — Control Table Driven with Full Logging
#
# Structure matches exactly the portal JSON export.
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
  foreach_activities = [
    # ── 1. Log Start ──────────────────────────────────────────────────────────
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
              value = "@concat('INSERT INTO [app].[pipeline_log] ([run_id],[activity_run_id],[pipeline_name],[source_entity],[target_schema],[target_table],[status],[from_date],[to_date],[watermark_start],[start_time],[environment],[triggered_by],[created_date]) VALUES (''', pipeline().RunId, ''',''', pipeline().RunId, ''',''', pipeline().parameters.pipeline_name, ''',''', item().source_entity, ''',''', item().target_schema, ''',''', item().target_table, ''',''RUNNING'',', if(empty(string(item().from_date)), 'NULL', concat('''', string(item().from_date), '''')), ',', if(empty(string(item().to_date)), 'NULL', concat('''', string(item().to_date), '''')), ',', if(empty(item().last_watermark), 'NULL', concat('''', item().last_watermark, '''')), ',''', utcNow(), ''',''', pipeline().parameters.environment, ''',''', pipeline().parameters.triggered_by, ''',''', utcNow(), ''')')"
              type  = "Expression"
            }
          }
        ]
        scriptBlockExecutionTimeout = "02:00:00"
      }
      externalReferences = {
        connection = var.warehouse_connection_id
      }
    },

    # ── 2. Copy PostgreSQL → Lakehouse raw files ──────────────────────────────
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
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"
          query = {
            value = "@if(empty(item().source_query_template), concat('SELECT * FROM ', item().target_schema, '.', item().source_entity), replace(replace(item().source_query_template, '@from_date', if(empty(string(item().from_date)), '1900-01-01 00:00:00', formatDateTime(item().from_date, 'yyyy-MM-dd HH:mm:ss'))), '@to_date', if(empty(string(item().to_date)), formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss'), formatDateTime(item().to_date, 'yyyy-MM-dd HH:mm:ss'))))"
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
        sink = {
          type = "ParquetSink"
          storeSettings = {
            type                 = "LakehouseWriteSettings"
            recursiveCompression = false
          }
          formatSettings = {
            type              = "ParquetWriteSettings"
            enableVertiParquet = true
          }
          datasetSettings = {
            annotations = []
            linkedService = {
              name = var.lakehouse_name
              properties = {
                annotations = []
                type        = "Lakehouse"
                typeProperties = {
                  workspaceId = var.workspace_id
                  artifactId  = var.lakehouse_id
                  rootFolder  = "Files"
                }
              }
            }
            type   = "Parquet"
            schema = []
            typeProperties = {
              location = {
                type = "LakehouseLocation"
                fileName = {
                  value = "@concat(item().source_entity, '_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.parquet')"
                  type  = "Expression"
                }
                folderPath = {
                  value = "@concat('raw/', item().source_entity, '/', formatDateTime(utcNow(), 'yyyy'), '/', formatDateTime(utcNow(), 'MM'), '/', formatDateTime(utcNow(), 'dd'))"
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

    # ── 3. Log Success ────────────────────────────────────────────────────────
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
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(activity('Copy_to_Raw').output.rowsRead), ', [rows_written]=', string(activity('Copy_to_Raw').output.rowsCopied), ', [end_time]=''', utcNow(), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [last_watermark]=', if(empty(item().watermark_column), 'NULL', concat('''', utcNow(), '''')), ', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id))"
              type  = "Expression"
            }
          }
        ]
        scriptBlockExecutionTimeout = "02:00:00"
      }
      externalReferences = {
        connection = var.warehouse_connection_id
      }
    },

    # ── 4. Log Failure ────────────────────────────────────────────────────────
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
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(activity('Copy_to_Raw').output.errors[0].Message, '''', ''''''), ''', [error_code]=''', activity('Copy_to_Raw').output.errors[0].Code, ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''FAILED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id))"
              type  = "Expression"
            }
          }
        ]
        scriptBlockExecutionTimeout = "02:00:00"
      }
      externalReferences = {
        connection = var.warehouse_connection_id
      }
    }
  ]

  # ── Outer pipeline activities ───────────────────────────────────────────────
  activities = [
    # Lookup — matches portal JSON exactly (AzureSqlSource with two datasetSettings)
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
          type         = "AzureSqlSource"
          queryTimeout = "02:00:00"
          partitionOption = "None"
          datasetSettings = {
            annotations = []
            schema      = []
            type        = "DataWarehouseTable"
            typeProperties = {
              schema = "app"
              table  = "pipeline_control"
            }
            externalReferences = {
              connection = var.warehouse_connection_id
            }
          }
          query = {
            value = "@concat('SELECT control_id, pipeline_name, source_system, source_entity, target_schema, target_table, source_query_template, watermark_column, last_watermark, load_type, priority, from_date, to_date FROM [app].[pipeline_control] WHERE [pipeline_name] = ''', pipeline().parameters.pipeline_name, ''' AND [is_active] = 1 ORDER BY [priority] ASC')"
            type  = "Expression"
          }
        }
        firstRowOnly = false
        datasetSettings = {
          annotations = []
          type        = "AzureSqlTable"
          schema      = []
          typeProperties = {
            schema   = "app"
            table    = "pipeline_control"
            database = var.sink_warehouse_name
          }
          externalReferences = {
            connection = var.warehouse_connection_id
          }
        }
      }
    },

    # ForEach — parallel within batch
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
        environment         = var.environment
        triggered_by        = var.triggered_by_default
      }
    }
  }
}
