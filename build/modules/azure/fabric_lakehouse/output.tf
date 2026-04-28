output "lakehouse" {
  value = fabric_lakehouse.this
}

output "lakehouse_id" {
  value = fabric_lakehouse.this.id
}

output "lakehouse_name" {
  value = fabric_lakehouse.this.display_name
}

output "onelake_files_path" {
  description = "OneLake path to the Lakehouse files directory."
  value       = fabric_lakehouse.this.properties.onelake_files_path
}

output "onelake_tables_path" {
  description = "OneLake path to the Lakehouse tables directory."
  value       = fabric_lakehouse.this.properties.onelake_tables_path
}

output "sql_connection_string" {
  description = "The SQL connection string for the Lakehouse SQL analytics endpoint."
  value       = fabric_lakehouse.this.properties.sql_endpoint_properties.connection_string
}
