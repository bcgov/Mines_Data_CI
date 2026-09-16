# ─────────────────────────────────────────────────────────────────────────────
# Pipeline schedules — daily at 08:00 and 17:00 Pacific.
#
# "Pacific Standard Time" is the Windows time zone ID and follows daylight
# saving on its own, so the runs stay at 8am / 5pm local across the PST ↔ PDT
# switch (i.e. 16:00/01:00 UTC in winter, 15:00/00:00 UTC in summer).
#
# Both pipelines share one Daily schedule carrying both times, rather than two
# separate schedules — fewer objects to keep in sync and it shows up as a
# single entry under the item's Schedule pane in the portal.
#
# Scheduled runs use the pipeline's *default* parameter values: the Fabric
# scheduler cannot pass parameters. That means override_from_date /
# override_to_date stay empty (normal incremental run off the stored
# watermark), which is exactly what a recurring load wants.
# ─────────────────────────────────────────────────────────────────────────────

module "schedule_pipeline_mds" {
  source = "../modules/azure/fabric_item_schedule"

  workspace_id = module.fabric_workspace_01.workspace_id
  item_id      = module.pipeline_raw_to_bronze.pipeline_id
  job_type     = "Pipeline"
  label        = "pl_ingest_mds"

  times              = ["08:00", "17:00"]
  local_time_zone_id = "Pacific Standard Time"
  enabled            = true
}

module "schedule_pipeline_mto" {
  source = "../modules/azure/fabric_item_schedule"

  workspace_id = module.fabric_workspace_01.workspace_id
  item_id      = module.pipeline_raw_to_bronze_mto.pipeline_id
  job_type     = "Pipeline"
  label        = "pl_ingest_mto"

  times              = ["08:00", "17:00"]
  local_time_zone_id = "Pacific Standard Time"
  enabled            = true
}

# ── Visibility in CI output ──────────────────────────────────────────────────

output "pipeline_schedule_ids" {
  description = "Schedule GUIDs per pipeline, for cross-checking against the Fabric portal."
  value = {
    pl_ingest_mds = module.schedule_pipeline_mds.schedule_id
    pl_ingest_mto = module.schedule_pipeline_mto.schedule_id
  }
}
