module "warehouse_mds_connection" {
  source = "../modules/azure/fabric_connection"

  providers = {
    fabric.auth = fabric.auth
  }

  display_name      = "warehouse-${var.PREFIX}-${var.PROJECT}-${var.ENVIRONMENT}"
  connection_type   = "Warehouse"
  connectivity_type = "ShareableCloud"

  # Captured from the warehouse module — no hardcoded endpoint
  server   = module.fabric_warehouse_01.warehouse_connection_string
  database = module.fabric_warehouse_01.warehouse.display_name

  owner_principal_ids = var.WORKSPACE_OWNERS
}