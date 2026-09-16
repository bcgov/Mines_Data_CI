output "pipeline" {
  value = try(fabric_data_pipeline.this[0], null)
}

output "pipeline_id" {
  value = try(fabric_data_pipeline.this[0].id, "")
}

output "pipeline_name" {
  value = try(fabric_data_pipeline.this[0].display_name, "")
}
