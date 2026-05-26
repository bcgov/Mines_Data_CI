module "pipeline_raw_to_bronze" {
  source = "../modules/azure/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  # ─── Workspace ──────────────────────────────────────────────────────────
  workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  display_name = "pl_ingest_mds"
  description  = "Control table driven: MDS Core PostgreSQL → Lakehouse raw parquet files"

  # Default shown in the portal run dialog
  pipeline_name_param_default = "pl_ingest_mds"

  # ─── Source: MDS Core PostgreSQL connection ──────────────────────────────
  source_connection_id = "21b383a1-c561-4540-980d-ce3683e89236"

  # ─── Control table + logging: Fabric Warehouse ──────────────────────────
  sink_warehouse_id   = "9ed9a608-33e5-408b-bd51-adc2dad1e7ab"
  sink_warehouse_name = "mines-data-platform-fabwh1"
  sink_endpoint       = "abjnw3ynhwfevmbw2nuf4nm23q-rahtrd7fltiurh5f7o734jufua.datawarehouse.fabric.microsoft.com"

  # ─── Sink: Lakehouse Files ───────────────────────────────────────────────
  # Files land at: raw/<source_entity>/yyyy/MM/dd/<source_entity>_yyyyMMdd_HHmmss.parquet
  lakehouse_name = "mines_data_platform_lh1"
  lakehouse_id   = "8cd34a44-500a-47d9-aa2d-5ad0c2149858"

  # Max parallel copies within a ForEach batch
  parallel_copies = 10
}

output "raw_to_bronze_pipeline_id" {
  value = module.pipeline_raw_to_bronze.pipeline_id
}

output "raw_to_bronze_run_command" {
  value = module.pipeline_raw_to_bronze.run_rest_command
}
