# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — Control Table Driven Incremental Loads with Replay
#
# Logging is delegated to one stored procedure (see logging_proc.sql):
#   [app].[usp_pipeline_log] @mode='START'  INSERT a RUNNING row into pipeline_log
#   [app].[usp_pipeline_log] @mode='END'    UPDATE that log row AND pipeline_control
#
# Watermark rule enforced inside the proc on END:
#   advance only when status = SUCCEEDED AND rows_written > 0
#   AND @new_watermark is non-null AND @advance = 1
#
# @new_watermark is the MAX(watermark_column) actually observed on the source
# during this run, capped by the rolling window (utcNow() - N days).
# It is NOT utcNow(), so rows arriving after the source max are never skipped.
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
  # ── Runtime expression fragments, raw expression text, no leading @ ────────

  # Unique log row key per control row inside a pipeline run.
  expr_activity_run_id = "concat(pipeline().RunId, '-', string(item().control_id))"

  # True when the caller supplied a replay/backfill window override.
  expr_has_date_override = "or(not(empty(pipeline().parameters.override_from_date)), not(empty(pipeline().parameters.override_to_date)))"

  # Lower bound precedence:
  #   1. runtime override_from_date
  #   2. control.last_watermark
  #   3. control.from_date
  #   4. 1900-01-01
  expr_from_effective = "if(not(empty(pipeline().parameters.override_from_date)), pipeline().parameters.override_from_date, if(empty(coalesce(item().last_watermark, '')), if(empty(string(item().from_date)), '1900-01-01 00:00:00', formatDateTime(item().from_date, 'yyyy-MM-dd HH:mm:ss')), item().last_watermark))"

  # Upper bound precedence:
  #   1. runtime override_to_date
  #   2. utcNow()
  expr_to_effective = "if(not(empty(pipeline().parameters.override_to_date)), pipeline().parameters.override_to_date, formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss'))"

  # Rolling window ceiling: never advance the watermark into the last N days.
  expr_rolling_cutoff = "formatDateTime(addDays(utcNow(), -${var.watermark_lag_days}), 'yyyy-MM-dd HH:mm:ss')"

  # MAX(watermark_column) observed on the source this run. Empty when the
  # window returned no rows (Postgres MAX over an empty set is NULL).
  expr_source_max = "coalesce(activity('Lookup_SourceMax').output?.firstRow?.max_watermark, '')"

  # new_watermark = LEAST(source_max, rolling_cutoff); empty when no rows found.
  # Empty is passed to the proc as NULL, which then does not advance.
  expr_new_watermark = "if(empty(${local.expr_source_max}), '', if(greater(${local.expr_source_max}, ${local.expr_rolling_cutoff}), ${local.expr_rolling_cutoff}, ${local.expr_source_max}))"

  # SQL literal helper: emits NULL (unquoted) or a quoted string.
  expr_new_watermark_sql = "if(empty(${local.expr_new_watermark}), 'NULL', concat('''', ${local.expr_new_watermark}, ''''))"

  # Watermark advances on normal runs; replay/backfill only when explicitly asked.
  expr_advance_flag = "if(or(not(${local.expr_has_date_override}), equals(toLower(pipeline().parameters.advance_watermark_on_override), 'true')), '1', '0')"

  # ── Policies ───────────────────────────────────────────────────────────────

  # Script writes hit Fabric Warehouse tables in parallel. Retries help survive
  # transient snapshot isolation update conflicts.
  policy_script = {
    timeout                = "0.00:05:00"
    retry                  = 5
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

  # ── Dataset settings ───────────────────────────────────────────────────────

  # Splits source_entity like public.standard_permit_conditions into schema/table.
  postgres_dataset = {
    annotations = []
    type        = "PostgreSqlTable"
    schema      = []

    typeProperties = {
      schema = {
        value = "@if(contains(item().source_entity, '.'), split(item().source_entity, '.')[0], 'public')"
        type  = "Expression"
      }

      table = {
        value = "@if(contains(item().source_entity, '.'), split(item().source_entity, '.')[1], item().source_entity)"
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
            value = "@concat(item().target_table, '_', formatDateTime(utcNow(), 'yyyyMMdd_HHmmss'), '.parquet')"
            type  = "Expression"
          }

          folderPath = {
            value = "@concat('raw/', item().target_schema, '/', item().target_table, '/', formatDateTime(utcNow(), 'yyyy'), '/', formatDateTime(utcNow(), 'MM'), '/', formatDateTime(utcNow(), 'dd'))"
            type  = "Expression"
          }
        }

        compressionCodec = "snappy"
      }
    }
  }

  # ── Incremental branch ─────────────────────────────────────────────────────

  incremental_activities = [
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
            value = "@concat('SELECT COALESCE(TO_CHAR(MAX(', item().watermark_column, '), ''YYYY-MM-DD HH24:MI:SS''), '''') AS max_watermark, COUNT(*) AS row_count FROM ', item().source_entity, ' WHERE ', item().watermark_column, ' >= ''', ${local.expr_from_effective}, ''' AND ', item().watermark_column, ' < ''', ${local.expr_to_effective}, '''')"
            type  = "Expression"
          }

          datasetSettings = local.postgres_dataset
        }

        firstRowOnly = true

        # Required by Fabric UI validation for Lookup connection.
        datasetSettings = local.postgres_dataset
      }
    },

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
            value = "@if(and(contains(toLower(coalesce(item().source_query_template, '')), '@from_date'), contains(toLower(coalesce(item().source_query_template, '')), '@to_date')), replace(replace(item().source_query_template, '@from_date', ${local.expr_from_effective}), '@to_date', ${local.expr_to_effective}), concat(coalesce(item().source_query_template, concat('SELECT * FROM ', item().source_entity)), if(contains(toLower(coalesce(item().source_query_template, '')), ' where '), ' AND ', ' WHERE '), item().watermark_column, ' >= ''', ${local.expr_from_effective}, ''' AND ', item().watermark_column, ' < ''', ${local.expr_to_effective}, ''''))"
            type  = "Expression"
          }

          datasetSettings = local.postgres_dataset
        }

        sink          = local.sink_parquet
        enableStaging = false
      }
    },

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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''END'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @control_id=', string(item().control_id), ', @status=''SUCCEEDED'', @rows_read=', string(coalesce(activity('Copy_Incremental').output?.rowsRead, 0)), ', @rows_written=', string(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0)), ', @watermark_end=', ${local.expr_new_watermark_sql}, ', @new_watermark=', ${local.expr_new_watermark_sql}, ', @window_from=''', ${local.expr_from_effective}, ''', @window_to=', ${local.expr_new_watermark_sql}, ', @advance=', ${local.expr_advance_flag})"
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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''END'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @control_id=', string(item().control_id), ', @status=''FAILED'', @rows_read=', string(coalesce(activity('Copy_Incremental').output?.rowsRead, 0)), ', @rows_written=', string(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0)), ', @error_message=''', replace(coalesce(activity('Copy_Incremental').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', @error_code=''', replace(coalesce(activity('Copy_Incremental').output?.errors[0]?.Code, 'Unknown'), '''', ''''''), '''')"
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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''END'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @control_id=', string(item().control_id), ', @status=''FAILED'', @error_message=''', replace(coalesce(activity('Lookup_SourceMax').error?.message, 'Lookup_SourceMax failed'), '''', ''''''), ''', @error_code=''LOOKUP_SOURCE_MAX_FAILED''')"
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

  # ── Full load branch ───────────────────────────────────────────────────────
  # No watermark column, so there is no source MAX to advance to. The snapshot
  # time is recorded instead, and only when rows were actually written.

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
            value = "@if(empty(coalesce(item().source_query_template, '')), concat('SELECT * FROM ', item().source_entity), replace(replace(item().source_query_template, '@from_date', ${local.expr_from_effective}), '@to_date', ${local.expr_to_effective}))"
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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''END'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @control_id=', string(item().control_id), ', @status=''SUCCEEDED'', @rows_read=', string(coalesce(activity('Copy_Full').output?.rowsRead, 0)), ', @rows_written=', string(coalesce(activity('Copy_Full').output?.rowsCopied, 0)), ', @new_watermark=', if(greater(coalesce(activity('Copy_Full').output?.rowsCopied, 0), 0), concat('''', ${local.expr_to_effective}, ''''), 'NULL'), ', @window_from=''', ${local.expr_from_effective}, ''', @window_to=''', ${local.expr_to_effective}, ''', @advance=', ${local.expr_advance_flag})"
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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''END'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @control_id=', string(item().control_id), ', @status=''FAILED'', @rows_read=', string(coalesce(activity('Copy_Full').output?.rowsRead, 0)), ', @rows_written=', string(coalesce(activity('Copy_Full').output?.rowsCopied, 0)), ', @error_message=''', replace(coalesce(activity('Copy_Full').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', @error_code=''', replace(coalesce(activity('Copy_Full').output?.errors[0]?.Code, 'Unknown'), '''', ''''''), '''')"
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

  # ── Per control-row activities ─────────────────────────────────────────────

  foreach_activities = [
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
              value = "@concat('EXEC [app].[usp_pipeline_log] @mode=''START'', @activity_run_id=''', ${local.expr_activity_run_id}, ''', @run_id=''', pipeline().RunId, ''', @pipeline_name=''', pipeline().parameters.pipeline_name, ''', @source_entity=''', item().source_entity, ''', @target_schema=''', item().target_schema, ''', @target_table=''', item().target_table, ''', @from_date=''', ${local.expr_from_effective}, ''', @to_date=''', ${local.expr_to_effective}, ''', @watermark_start=', if(empty(coalesce(item().last_watermark, '')), 'NULL', concat('''', item().last_watermark, '''')), ', @environment=''', pipeline().parameters.environment, ''', @triggered_by=''', pipeline().parameters.triggered_by, '''')"
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
          value = "@and(equals(toUpper(coalesce(item().load_type, '')), 'INCREMENTAL'), not(empty(coalesce(item().watermark_column, ''))))"
          type  = "Expression"
        }

        ifTrueActivities  = local.incremental_activities
        ifFalseActivities = local.fullload_activities
      }
    }
  ]

  # ── Outer pipeline activities ──────────────────────────────────────────────

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

          # table_filter_csv accepts target table names, for example:
          #   standard_permit_conditions,camp_detail
          sqlReaderQuery = {
            value = "@concat('SELECT control_id, pipeline_name, source_system, source_entity, target_schema, target_table, source_query_template, watermark_column, last_watermark, load_type, priority, from_date, to_date FROM [app].[pipeline_control] WHERE [pipeline_name] = ''', pipeline().parameters.pipeline_name, ''' AND [is_active] = 1 ', if(empty(pipeline().parameters.table_filter_csv), '', concat('AND [target_table] IN (''', replace(pipeline().parameters.table_filter_csv, ',', ''','''), ''') ')), 'ORDER BY [priority] ASC')"
            type  = "Expression"
          }

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

        override_from_date            = ""
        override_to_date              = ""
        table_filter_csv              = ""
        advance_watermark_on_override = "false"
      }
    }
  }
}
