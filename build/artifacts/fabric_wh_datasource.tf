module "warehouse_mds_connection" {
  source = "../modules/azure/fabric_connection"

  display_name      = "warehouse-mines-data-platform"
  connection_type   = "Warehouse"
  connectivity_type = "ShareableCloud"

  server   = "abjnw3ynhwfevmbw2nuf4nm23q-rahtrd7fltiurh5f7o734jufua.datawarehouse.fabric.microsoft.com"
  database = "mines-data-platform-fabwh1"
}