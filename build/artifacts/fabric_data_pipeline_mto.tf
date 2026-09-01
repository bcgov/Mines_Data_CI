
module "pipeline_raw_to_bronze_mto" {
  source = "../modules/azure/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  environment                 = var.ENVIRONMENT
  workspace_id                = module.fabric_workspace_01.workspace_id
  display_name                = "pl_ingest_mto"
  pipeline_name_param_default = "pl_ingest_mto"

  source_connection_id    = "21b383a1-c561-4540-980d-ce3683e89236"
  warehouse_connection_id = module.warehouse_mds_connection.connection_id

  lakehouse_name  = module.fabric_lakehouse_01.lakehouse_name
  lakehouse_id    = module.fabric_lakehouse_01.lakehouse_id
  parallel_copies = 10
}
