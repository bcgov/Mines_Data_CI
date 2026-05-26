

module "pipeline_mds_to_bronze" {
  source = "../modules/azure/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  # ─── Workspace ──────────────────────────────────────────────────────────
  workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  display_name = "pl-mds-core-to-bronze-01"
  description  = "On-demand copy: MDS Core PostgreSQL → Fabric Warehouse bronze layer"

  # ─── Source: existing MDS Core connection ───────────────────────────────
  source_connection_id = "ba89abfc-8b16-4141-87de-8bc02accfe28"
  source_database      = "mds"
  source_schema        = "public"

  # ─── Sink: Fabric Warehouse mines-data-platform-fabwh1 ──────────────────
  sink_workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  sink_warehouse_id = "9ed9a608-33e5-408b-bd51-adc2dad1e7ab"
  sink_schema       = "bronze"

  # Auto-create tables on first run
  table_option  = "autoCreate"
  write_behavior = "insert"

  # ─── Tables to copy ─────────────────────────────────────────────────────
  table_mappings = [
    { source_table = "etl_permit",   sink_table = "etl_permit"   },
    { source_table = "camp_detail",  sink_table = "camp_detail"  },
  ]
}



output "pipeline_id"       { value = module.pipeline_mds_to_bronze.pipeline_id }
output "run_rest_command"  { value = module.pipeline_mds_to_bronze.run_rest_command }
