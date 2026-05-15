
module "postgres_mds_via_vnet_gateway" {
  source = "../modules/azure/fabric_connection"

  display_name      = "postgres-mds-via-vnet-gw"
  connection_type   = "PostgreSQL"

  connectivity_type = "VirtualNetworkGateway"
  gateway_id        = "f15b9af0-2bda-4add-85a1-066d89935a82"

  server   = "mds-reporting-pg13-live.postgres.database.azure.com"
  database = "mds"

  username = "fakeuser"
  password = "fakepassword"

  skip_test_connection = false
}
