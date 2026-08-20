module "postgres_mds_test_connection" {
  source = "../modules/azure/fabric_connection"

  display_name      = "postgres-mds-test"
  connection_type   = "PostgreSQL"
  connectivity_type = "VirtualNetworkGateway"
  gateway_id        = "f15b9af0-2bda-4add-85a1-066d89935a82"

  server   = "142.34.194.69"
  port     = 48625
  database = "mds"
  username = "mds_data_analytics"
  password = var.mds_test_password
  owner_principal_ids = ["b0bf68e8-4e08-433c-8903-19b2fec4cc20"]
}

output "postgres_mds_test_connection_id" {
  description = "Pass this into pipeline modules as source_connection_id for MDS Core Test."
  value       = module.postgres_mds_test_connection.connection_id
}
