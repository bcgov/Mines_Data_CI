# ─── Target item ─────────────────────────────────────────────────────────────

variable "workspace_id" {
  type        = string
  description = "Fabric workspace ID that owns the item being scheduled."
}

variable "item_id" {
  type        = string
  description = "Fabric item ID to schedule (e.g. module.pipeline_x.pipeline_id)."
}

variable "job_type" {
  type        = string
  description = "Fabric job type for the item. Data Pipelines use 'Pipeline'; notebooks use 'RunNotebook'."
  default     = "Pipeline"
}

variable "label" {
  type        = string
  description = "Human-readable name used only in log output, so a CI run shows which pipeline was scheduled."
  default     = ""
}

# ─── Recurrence ──────────────────────────────────────────────────────────────

variable "times" {
  type        = list(string)
  description = "Daily run times in hh:mm (24h), local to local_time_zone_id. Max 100 slots."
  default     = ["08:00", "17:00"]

  validation {
    condition     = alltrue([for t in var.times : can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", t))])
    error_message = "Each entry in times must be hh:mm in 24-hour format, e.g. 08:00 or 17:00."
  }
}

variable "local_time_zone_id" {
  type        = string
  description = <<-DESC
    Windows time zone ID the times are interpreted in. "Pacific Standard Time"
    covers BC and observes daylight saving automatically, so 08:00 stays 08:00
    local year-round. Do not use IANA names like America/Vancouver here.
  DESC
  default     = "Pacific Standard Time"
}

variable "enabled" {
  type        = bool
  description = "Whether the schedule is active. Set false to keep the trigger defined but paused."
  default     = true
}

variable "start_date_time" {
  type        = string
  description = <<-DESC
    Schedule activation timestamp, yyyy-MM-ddTHH:mm:ss. Kept as a fixed literal
    (not a timestamp() call) so re-applying does not change the payload hash and
    re-trigger the schedule on every run.
  DESC
  default     = "2026-01-01T00:00:00"
}

variable "end_date_time" {
  type        = string
  description = "Schedule expiry timestamp, yyyy-MM-ddTHH:mm:ss. Must be later than start_date_time."
  default     = "2099-12-31T23:59:00"
}
