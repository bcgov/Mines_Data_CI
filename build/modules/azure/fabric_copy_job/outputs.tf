output "copy_job_id" {
  description = "GUID of the created Copy Job."
  value       = fabric_copy_job.this.id
}

output "copy_job_display_name" {
  description = "Display name."
  value       = fabric_copy_job.this.display_name
}

output "run_command" {
  description = "Fabric CLI command to trigger this Copy Job on-demand."
  value       = "fab job run -w ${var.workspace_id} -i ${fabric_copy_job.this.id}"
}
