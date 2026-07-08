# ─────────────────────────────────────────────────────────────────────────────
# Fabric Data Pipeline — Control Table Driven Incremental Loads with Replay
#
# Goals:
#   1. Normal incremental loads use persisted control-table state.
#   2. Users can override from/to dates at pipeline runtime for replay/backfill.
#   3. Users can run a subset of tables using table_filter_csv.
#   4. ForEach stays parallel.
#   5. Script activities retry Fabric Warehouse snapshot conflicts.
#
# Expected control table pattern:
#   source_entity = public.standard_permit_conditions
#   target_schema = bronze
#   target_table  = standard_permit_conditions
#
# Expected source_query_template example:
#   SELECT *
#   FROM public.standard_permit_conditions
#   WHERE update_timestamp >= '@from_date'
#     AND update_timestamp < '@to_date'
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
  # ── Runtime expression fragments, raw ADF/Fabric expression text, no leading @ ──

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
  #
  # Note: control.to_date is treated as the previous processed upper bound / audit checkpoint.
  # It is NOT used as the next upper bound, otherwise a run where from_date == to_date
  # would create an empty window.
  expr_to_effective = "if(not(empty(pipeline().parameters.override_to_date)), pipeline().parameters.override_to_date, formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss'))"

  # For non-incremental/full rows, move the old to_date into from_date and set to_date to utcNow().
  # If to_date is empty, fall back to the existing from_effective value.
  expr_full_from_update = "if(empty(string(item().to_date)), ${local.expr_from_effective}, formatDateTime(item().to_date, 'yyyy-MM-dd HH:mm:ss'))"
  expr_full_to_update   = "formatDateTime(utcNow(), 'yyyy-MM-dd HH:mm:ss')"

  # Watermark should advance for normal incremental runs.
  # Replay/backfill overrides do not advance the persisted watermark unless explicitly requested.
  expr_should_advance_watermark = "or(not(${local.expr_has_date_override}), equals(toLower(pipeline().parameters.advance_watermark_on_override), 'true'))"

  # Optional: source MAX for logging/diagnostics only. The persisted watermark advances to to_effective.
  expr_source_max = "coalesce(activity('Lookup_SourceMax').output?.firstRow?.max_watermark, '')"

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
  # If source_entity has no dot, schema defaults to public.
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
            value = "@concat('SELECT TO_CHAR(MAX(', item().watermark_column, '), ''YYYY-MM-DD HH24:MI:SS'') AS max_watermark, COUNT(*) AS row_count FROM ', item().source_entity, ' WHERE ', item().watermark_column, ' >= ''', ${local.expr_from_effective}, ''' AND ', item().watermark_column, ' < ''', ${local.expr_to_effective}, '''')"
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
            value = "@if(and(contains(toLower(coalesce(item().source_query_template, '')), '@from_date'), contains(toLower(coalesce(item().source_query_template, '')), '@to_date')), replace(replace(item().source_query_template, '@from_date', ${local.expr_from_effective}), '@to_date', ${local.expr_to_effective}), concat(item().source_query_template, if(contains(toLower(item().source_query_template), ' where '), ' AND ', ' WHERE '), item().watermark_column, ' >= ''', ${local.expr_from_effective}, ''' AND ', item().watermark_column, ' < ''', ${local.expr_to_effective}, ''''))"
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
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(coalesce(activity('Copy_Incremental').output?.rowsRead, 0)), ', [rows_written]=', string(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0)), ', [watermark_end]=''', ${local.expr_to_effective}, ''', [source_max_watermark]=''', ${local.expr_source_max}, ''', [end_time]=''', utcNow(), ''' WHERE [activity_run_id]=''', ${local.expr_activity_run_id}, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"

            text = {
              value = "@if(greater(coalesce(activity('Copy_Incremental').output?.rowsCopied, 0), 0), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [last_watermark]=''', ${local.expr_to_effective}, ''', [from_date]=''', ${local.expr_to_effective}, ''', [to_date]=''', ${local.expr_to_effective}, ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)))"
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
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Copy_Incremental').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', [error_code]=''', coalesce(activity('Copy_Incremental').output?.errors[0]?.Code, 'Unknown'), ''' WHERE [activity_run_id]=''', ${local.expr_activity_run_id}, '''')"
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
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Lookup_SourceMax').error?.message, 'Lookup_SourceMax failed'), '''', ''''''), ''', [error_code]=''LOOKUP_SOURCE_MAX_FAILED'' WHERE [activity_run_id]=''', ${local.expr_activity_run_id}, '''')"
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

  # ── Full load branch ───────────────────────────────────────────────────────

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
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''SUCCEEDED'', [rows_read]=', string(coalesce(activity('Copy_Full').output?.rowsRead, 0)), ', [rows_written]=', string(coalesce(activity('Copy_Full').output?.rowsCopied, 0)), ', [end_time]=''', utcNow(), ''' WHERE [activity_run_id]=''', ${local.expr_activity_run_id}, '''')"
              type  = "Expression"
            }
          },
          {
            type = "NonQuery"

            text = {
              value = "@if(greater(coalesce(activity('Copy_Full').output?.rowsCopied, 0), 0), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [from_date]=''', ${local.expr_full_from_update}, ''', [to_date]=''', ${local.expr_full_to_update}, ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)), concat('UPDATE [app].[pipeline_control] SET [last_run_status]=''SUCCEEDED'', [last_run_date]=''', utcNow(), ''', [modified_date]=''', utcNow(), ''' WHERE [control_id]=', string(item().control_id)))"
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
              value = "@concat('UPDATE [app].[pipeline_log] SET [status]=''FAILED'', [end_time]=''', utcNow(), ''', [error_message]=''', replace(coalesce(activity('Copy_Full').output?.errors[0]?.Message, 'Copy failed'), '''', ''''''), ''', [error_code]=''', coalesce(activity('Copy_Full').output?.errors[0]?.Code, 'Unknown'), ''' WHERE [activity_run_id]=''', ${local.expr_activity_run_id}, '''')"
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
              value = "@concat('INSERT INTO [app].[pipeline_log] ([run_id],[activity_run_id],[pipeline_name],[source_entity],[target_schema],[target_table],[status],[from_date],[to_date],[watermark_start],[start_time],[environment],[triggered_by],[created_date]) VALUES (''', pipeline().RunId, ''',''', ${local.expr_activity_run_id}, ''',''', pipeline().parameters.pipeline_name, ''',''', item().source_entity, ''',''', item().target_schema, ''',''', item().target_table, ''',''RUNNING'',''', ${local.expr_from_effective}, ''',''', ${local.expr_to_effective}, ''',', if(empty(coalesce(item().last_watermark, '')), 'NULL', concat('''', item().last_watermark, '''')), ',''', utcNow(), ''',''', pipeline().parameters.environment, ''',''', pipeline().parameters.triggered_by, ''',''', utcNow(), ''')')"
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

          # AzureSqlSource uses sqlReaderQuery, not query.
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
        # Keep parallel execution.
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

        # Add matching parameters to pipeline-content.json.tmpl.
        override_from_date             = ""
        override_to_date               = ""
        table_filter_csv               = ""
        advance_watermark_on_override  = "false"
      }
    }
  }
}
