output "pipeline_id" {
  description = "GUID of the created Data Pipeline."
  value       = fabric_data_pipeline.this.id
}

output "pipeline_display_name" {
  description = "Display name of the Data Pipeline."
  value       = fabric_data_pipeline.this.display_name
}

output "run_rest_command" {
  description = "curl command to trigger this pipeline on-demand (replace TOKEN)."
  value       = "curl -X POST -H 'Authorization: Bearer $TOKEN' 'https://api.fabric.microsoft.com/v1/workspaces/${var.workspace_id}/items/${fabric_data_pipeline.this.id}/jobs/instances?jobType=Pipeline'"
}
