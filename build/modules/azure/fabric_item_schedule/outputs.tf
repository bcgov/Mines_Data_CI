output "schedule_id" {
  description = "GUID of the Fabric item schedule — stored in Terraform state."
  value       = data.external.schedule_id.result.id
}

output "times" {
  description = "Daily run times applied to the item, local to local_time_zone_id."
  value       = var.times
}

output "local_time_zone_id" {
  description = "Windows time zone the run times are interpreted in."
  value       = var.local_time_zone_id
}

output "enabled" {
  description = "Whether the schedule is currently active."
  value       = var.enabled
}
