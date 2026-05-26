module "pipeline_raw_to_bronze" {
  source = "../modules/azure/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  display_name = "raw_to_bronze"
  description  = "On-demand copy: MDS Core PostgreSQL → Lakehouse raw parquet files"

  source_connection_id = "21b383a1-c561-4540-980d-ce3683e89236"
  source_database      = "mds"
  source_schema        = "public"

  lakehouse_name = "mines_data_platform_lh1"
  lakehouse_id   = "8cd34a44-500a-47d9-aa2d-5ad0c2149858"

  table_mappings = [
    { source_table = "etl_permit",  sink_table = "etl_permit"  },
    { source_table = "camp_detail", sink_table = "camp_detail" },
  ]
}