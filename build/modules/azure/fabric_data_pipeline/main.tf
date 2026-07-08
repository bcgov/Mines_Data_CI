# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — Control Table Driven with Full Logging
#
# Watermark strategy (per control row, per run):
#   from_effective = coalesce(last_watermark, from_date, '1900-01-01')
#   to_effective   = coalesce(to_date, utcNow())          -- to_date = optional backfill ceiling
#
#   INCREMENTAL rows (load_type = 'INCREMENTAL' AND watermark_column is set
#   AND source_query_template contains the watermark column, e.g. update_timestamp):
#     1. Lookup_SourceMax queries MAX(watermark_column) on the SOURCE table
#        within [from_effective, to_effective) at run time.
#     2. Copy runs with the same window.
#     3. Only if rowsCopied > 0:
#          new_watermark = LEAST(source_max, utcNow() - 7 days)   -- rolling 7-day window
#          UPDATE pipeline_control SET last_watermark = new_watermark,
#                                      from_date      = new_watermark
#        If 0 rows were copied the watermark is NOT advanced.
#
#   All other rows (full load): plain SELECT * FROM source_entity, no watermark update.
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
  # ── Reusable ADF expression fragments (raw, no leading @) ──────────────────

  # Prefer last_watermark; fall back to static from_date; fall back to 1900.
  expr_from_effective = "if(empty(coalesce(item().last_watermark, '')), if(empty(string(item().from_date)), '1900-01-01 00:00:00', formatDateTime(item().from_date, 'yyyy-MM-dd HH:mm:ss')), item().last_watermark)"

  # Optional static ceiling; otherwise now.
  expr_to_effective = "if(empty(string(item().to_date)), formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss'), formatDateTime(item().to_date, 'yyyy-MM-dd HH:mm:ss'))"

  # Rolling window: never advance the watermark past utcNow() - 7 days.
  expr_rolling_cutoff = "formatDateTime(addDays(utcNow(), -7), 'yyyy-MM-dd HH:mm:ss')"

  # MAX(watermark_column) found on the source at run time (null-safe).
  expr_source_max = "coalesce(activity('Lookup_SourceMax').output?.firstRow?.max_watermark, ${local.expr_rolling_cutoff})"

  # new_watermark = LEAST(source_max, utcNow() - 7 days)
  expr_new_watermark = "if(greater(${local.expr_source_max}, ${local.expr_rolling_cutoff}), ${local.expr_rolling_cutoff}, ${local.expr_source_max})"

  # ── Reusable blocks ─────────────────────────────────────────────────────────

  policy_script = {
    timeout                = "0.00:05:00"
    retry                  = 0
    retryIntervalInSeconds = 30
    secureOutput           = false
    secureInput            = false
  }

  policy_activity = {
    timeout                = var.activity_timeout
    retry                  = var.activity_retry
    retryIntervalInSeconds = 30
    secureOutput           = false
    secureInput            = false
  }

  postgres_dataset = {
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

  sink_parquet = {
    type = "ParquetSink"
    storeSettings = {
      type                 = "LakehouseWriteSettings"
      recursiveCompression = false
    }
    formatSettings = {
      type               = "ParquetWriteSettings"
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

  # ── INCREMENTAL branch ──────────────────────────────────────────────────────
  incremental_activities = [
    # 1. Find MAX(watermark) on the source at the time of the run
    {
      name      = "Lookup_SourceMax"
      type      = "Lookup"
      dependsOn = []
      policy    = local.policy_activity
      typeProperties = {
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"
          query = {
            value = "@concat('SELECT TO_CHAR(MAX(', item().watermark_column, '), ''YYYY-MM-DD HH24:MI:SS'') AS max_watermark, COUNT(*) AS row_count FROM ', item().source_entity, ' WHERE ', item().watermark_column, ' >= ''', ${local.expr_from_effective}, ''' AND ', item().watermark_column, ' < ''', ${local.expr_to_effective}, '''')"
            type  = "Expression"
          }
          datasetSettings = local.postgres_dataset
        }
        firstRowOnly = true
      }
    },

    # 2. Copy the same window
    {
      name = "Copy_Incremental"
      type = "Copy"
      dependsOn = [
        {
          activity             = "Lookup_SourceMax"
          dependencyConditions = ["Succeeded"]
        }
      ]
      policy = local.policy_activity
      typeProperties = {
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"
          query = {
            value = "@replace(replace(item().source_query_template, '@from_date', ${local.expr_from_effective}), '@to_date', ${local.expr_to_effective})"
            type  = "Expression"
          }
          datasetSettings = local.postgres_dataset
        }
        sink          = local.sink_parquet
        enableStaging = false
      }
    },

    # 3a. Success: log rows, advance watermark ONLY if rowsCopied > 0
    {
      name = "Log_Success_Incremental"
      type = "Script"
      dependsOn = [
        {
          activity             = "Copy_Incremental"
          dependencyConditions = ["Succeeded"]
        }
      ]
      policy = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(coalesce(activity('Copy_Incremental').output?.rowsRead, 0)), ', [rows_written]=', string(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0)), ', [watermark_end]=''', ${local.expr_new_watermark}, ''', [end_time]=''', utcNow(), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"
            text = {
              value = "@if(greater(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0), 0), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [last_watermark]=''', ${local.expr_new_watermark}, ''', [from_date]=''', ${local.expr_new_watermark}, ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)))"
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

    # 3b. Copy failed: watermark untouched
    {
      name = "Log_Failure_Incremental"
      type = "Script"
      dependsOn = [
        {
          activity             = "Copy_Incremental"
          dependencyConditions = ["Failed"]
        }
      ]
      policy = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Copy_Incremental').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', [error_code]=''', coalesce(activity('Copy_Incremental').output?.errors[0]?.Code, 'Unknown'), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
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
    },

    # 3c. Lookup failed: watermark untouched
    {
      name = "Log_Failure_Lookup"
      type = "Script"
      dependsOn = [
        {
          activity             = "Lookup_SourceMax"
          dependencyConditions = ["Failed"]
        }
      ]
      policy = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Lookup_SourceMax').error?.message, 'Lookup_SourceMax failed'), '''', ''''''), ''', [error_code]=''LOOKUP_SOURCE_MAX_FAILED'' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
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

  # ── FULL LOAD branch (or incremental rows whose template lacks the watermark
  #    column — falls back to running the template / SELECT * with no watermark
  #    update so nothing silently advances) ─────────────────────────────────────
  fullload_activities = [
    {
      name      = "Copy_Full"
      type      = "Copy"
      dependsOn = []
      policy    = local.policy_activity
      typeProperties = {
        source = {
          type         = "PostgreSqlSource"
          queryTimeout = "02:00:00"
          query = {
            value = "@if(empty(item().source_query_template), concat('SELECT * FROM ', item().source_entity), replace(replace(item().source_query_template, '@from_date', ${local.expr_from_effective}), '@to_date', ${local.expr_to_effective}))"
            type  = "Expression"
          }
          datasetSettings = local.postgres_dataset
        }
        sink          = local.sink_parquet
        enableStaging = false
      }
    },

    {
      name = "Log_Success_Full"
      type = "Script"
      dependsOn = [
        {
          activity             = "Copy_Full"
          dependencyConditions = ["Succeeded"]
        }
      ]
      policy = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(coalesce(activity('Copy_Full').output?.rowsRead, 0)), ', [rows_written]=', string(coalesce(activity('Copy_Full').output?.rowsCopied, 0)), ', [end_time]=''', utcNow(), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"
            text = {
              value = "@if(greater(coalesce(activity('Copy_Full').output?.rowsCopied, 0), 0), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [last_watermark]=''', formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss'), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)))"
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

    {
      name = "Log_Failure_Full"
      type = "Script"
      dependsOn = [
        {
          activity             = "Copy_Full"
          dependencyConditions = ["Failed"]
        }
      ]
      policy = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Copy_Full').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', [error_code]=''', coalesce(activity('Copy_Full').output?.errors[0]?.Code, 'Unknown'), ''' WHERE [run_id]=''', pipeline().RunId, ''' AND [source_entity]=''', item().source_entity, '''')"
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

  # ── Per-item activities ─────────────────────────────────────────────────────
  foreach_activities = [
    # 1. Log Start
    {
      name      = "Log_Start"
      type      = "Script"
      dependsOn = []
      policy    = local.policy_script
      typeProperties = {
        scripts = [
          {
            type = "NonQuery"
            text = {
              value = "@concat('INSERT INTO [app].[pipeline_log] ([run_id],[activity_run_id],[pipeline_name],[source_entity],[target_schema],[target_table],[status],[from_date],[to_date],[watermark_start],[start_time],[environment],[triggered_by],[created_date]) VALUES (''', pipeline().RunId, ''',''', pipeline().RunId, ''',''', pipeline().parameters.pipeline_name, ''',''', item().source_entity, ''',''', item().target_schema, ''',''', item().target_table, ''',''RUNNING'',''', ${local.expr_from_effective}, ''',''', ${local.expr_to_effective}, ''',', if(empty(coalesce(item().last_watermark, '')), 'NULL', concat('''', item().last_watermark, '''')), ',''', utcNow(), ''',''', pipeline().parameters.environment, ''',''', pipeline().parameters.triggered_by, ''',''', utcNow(), ''')')"
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

    # 2. Branch: watermark-driven incremental vs full load
    {
      name = "If_Incremental"
      type = "IfCondition"
      dependsOn = [
        {
          activity             = "Log_Start"
          dependencyConditions = ["Succeeded"]
        }
      ]
      typeProperties = {
        expression = {
          value = "@and(equals(coalesce(item().load_type, ''), 'INCREMENTAL'), and(not(empty(coalesce(item().watermark_column, ''))), contains(toLower(coalesce(item().source_query_template, '')), toLower(coalesce(item().watermark_column, 'zz_no_watermark')))))"
          type  = "Expression"
        }
        ifTrueActivities  = local.incremental_activities
        ifFalseActivities = local.fullload_activities
      }
    }
  ]

  # ── Outer pipeline activities ───────────────────────────────────────────────
  activities = [
    {
      name      = "Lookup_ControlTable"
      type      = "Lookup"
      dependsOn = []
      policy    = local.policy_activity
      typeProperties = {
        source = {
          type            = "AzureSqlSource"
          queryTimeout    = "02:00:00"
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
