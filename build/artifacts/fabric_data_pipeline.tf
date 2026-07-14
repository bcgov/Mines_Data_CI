# module "pipeline_raw_to_bronze" {
#   source = "../modules/azure/fabric_data_pipeline"

#   providers = {
#     fabric.auth = fabric.auth
#   }

#   environment                 = var.ENVIRONMENT
#   workspace_id                = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
#   display_name                = "pl_ingest_mds"
#   pipeline_name_param_default = "pl_ingest_mds"

#   source_connection_id    = "21b383a1-c561-4540-980d-ce3683e89236"
#   warehouse_connection_id = module.warehouse_mds_connection.connection_id

#   lakehouse_name  = "mines_data_platform_lh1"
#   lakehouse_id    = "8cd34a44-500a-47d9-aa2d-5ad0c2149858"
#   parallel_copies = 10
# }