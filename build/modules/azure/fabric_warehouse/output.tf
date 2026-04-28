output "warehouse" {
  value = fabric_warehouse.this_warehouse
}

output "warehouse_id" {
  value = fabric_warehouse.this_warehouse.id
}

output "warehouse_connection_string" {
  description = "The SQL connection string for the warehouse."
  value       = fabric_warehouse.this_warehouse.connection_string
}