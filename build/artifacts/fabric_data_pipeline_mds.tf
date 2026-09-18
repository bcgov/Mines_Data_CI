
module "pipeline_raw_to_bronze" {
  source = "../modules/azure/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  environment                 = var.ENVIRONMENT
  workspace_id                = module.fabric_workspace_01.workspace_id
  folder_id                   = local.fabric_item_folder_ids["pipelines"]
  display_name                = "pl_ingest_mds"
  pipeline_name_param_default = "pl_ingest_mds"

  source_connection_id    = "67a5f546-3911-48dd-aaf1-f5d501391517"
  # This environment's warehouse connection, resolved from Terraform state
  # (see warehouse_connection.tf).
  warehouse_connection_id = local.warehouse_connection_id

  # Warehouse display name, written into the Lookup datasets and every logging
  # Script activity as the `database`. Sourced from the warehouse module so it
  # can never drift from the warehouse that actually exists in this environment.
  sink_warehouse_name = module.fabric_warehouse_01.warehouse.display_name

  lakehouse_name  = module.fabric_lakehouse_01.lakehouse_name
  lakehouse_id    = module.fabric_lakehouse_01.lakehouse_id
  parallel_copies = 10
}
