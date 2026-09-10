
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
  # Pinned to the working warehouse connection rather than
  # module.warehouse_mds_connection.connection_id. That module resolves the ID
  # by listing connections and matching on display name, and returns "" when the
  # lookup misses — which is how an empty connection reached the pipeline JSON.
  # Same pattern already used above for source_connection_id.
  warehouse_connection_id = var.WAREHOUSE_CONNECTION_ID

  # Warehouse display name, written into the Lookup datasets and every logging
  # Script activity as the `database`. Sourced from the warehouse module so it
  # can never drift from the warehouse that actually exists in this environment.
  sink_warehouse_name = module.fabric_warehouse_01.warehouse.display_name

  lakehouse_name  = module.fabric_lakehouse_01.lakehouse_name
  lakehouse_id    = module.fabric_lakehouse_01.lakehouse_id
  parallel_copies = 10
}
