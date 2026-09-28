# ─────────────────────────────────────────────────────────────────────────────
# pl_daily_load — the one scheduled pipeline. Runs the whole chain, no manual
# step:
#
#   pl_ingest_mds ─┐
#                  ├─(Completed)─► pl_bronze_to_gold
#   pl_ingest_mto ─┘                (bronze → silver → gold → model refresh)
#
# Both ingest pipelines run in parallel. pl_bronze_to_gold starts when BOTH
# have finished, whatever their status ("Completed", not "Succeeded"):
# pl_ingest_mds reports Failed on most runs because a few control rows fail
# (a missing source view, a bad incremental filter, and snapshot-isolation
# conflicts on app.pipeline_log), while every other table still lands in raw.
# Waiting for "Succeeded" would mean the reports never refresh.
# A failed ingest is still visible on its own run in the Monitor hub.
#
# The schedule sits on this pipeline only (fabric_pipeline_schedules.tf); the
# ingest pipelines' own schedules are switched off so nothing runs twice.
#
# "Invoke pipeline (Legacy)" (ExecutePipeline) is used on purpose: it calls a
# pipeline in the same workspace by item id and needs no connection. The newer
# InvokePipeline activity needs a Fabric Data Pipelines connection per env.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  daily_load_activities = [
    {
      name        = "Ingest_MDS"
      type        = "ExecutePipeline"
      description = "MDS source -> Files/raw (Sebastian's pl_ingest_mds)"
      dependsOn   = []
      policy      = { secureInput = false }
      typeProperties = {
        pipeline         = { referenceName = module.pipeline_raw_to_bronze.pipeline_id, type = "PipelineReference" }
        waitOnCompletion = true
        parameters       = {}
      }
    },
    {
      name        = "Ingest_MTO"
      type        = "ExecutePipeline"
      description = "MTO source -> Files/raw (Sebastian's pl_ingest_mto)"
      dependsOn   = []
      policy      = { secureInput = false }
      typeProperties = {
        pipeline         = { referenceName = module.pipeline_raw_to_bronze_mto.pipeline_id, type = "PipelineReference" }
        waitOnCompletion = true
        parameters       = {}
      }
    },
    {
      name        = "Bronze_To_Gold"
      type        = "ExecutePipeline"
      description = "Raw -> bronze -> silver -> gold -> Gold model refresh"
      dependsOn = [
        { activity = "Ingest_MDS", dependencyConditions = ["Completed"] },
        { activity = "Ingest_MTO", dependencyConditions = ["Completed"] },
      ]
      policy = { secureInput = false }
      typeProperties = {
        pipeline         = { referenceName = fabric_data_pipeline.bronze_to_gold.id, type = "PipelineReference" }
        waitOnCompletion = true
        parameters       = {}
      }
    },
  ]
}

resource "fabric_data_pipeline" "daily_load" {
  provider     = fabric.auth
  workspace_id = module.fabric_workspace_01.workspace_id
  folder_id    = local.fabric_item_folder_ids["pipelines"]
  display_name = "pl_daily_load"
  description  = "Scheduled master: pl_ingest_mds + pl_ingest_mto, then pl_bronze_to_gold."
  format       = "Default"

  definition_update_enabled = true

  definition = {
    "pipeline-content.json" = {
      source = "${path.module}/pl_daily_load.json.tpl"
      tokens = {
        activities_json = jsonencode(local.daily_load_activities)
      }
    }
  }
}

output "pipeline_daily_load_id" {
  description = "pl_daily_load item ID (the scheduled master pipeline)."
  value       = fabric_data_pipeline.daily_load.id
}
