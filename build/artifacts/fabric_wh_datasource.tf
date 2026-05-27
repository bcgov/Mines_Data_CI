module "warehouse_mds_connection" {
  source = "../modules/azure/fabric_connection"

  providers = {
    fabric.auth = fabric.auth
  }

  display_name      = "warehouse-mines-data-platform"
  connection_type   = "Warehouse"
  connectivity_type = "ShareableCloud"

  workspace_id  = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  warehouse_id  = "9ed9a608-33e5-408b-bd51-adc2dad1e7ab"
}

output "warehouse_connection_id" {
  description = "Pass this into pipeline modules as warehouse_connection_id."
  value       = module.warehouse_mds_connection.connection_id
}
