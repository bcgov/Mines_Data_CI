output "pipeline" {
  value = fabric_data_pipeline.this
}

output "pipeline_id" {
  value = fabric_data_pipeline.this.id
}

output "pipeline_name" {
  value = fabric_data_pipeline.this.display_name
}
