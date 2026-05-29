# ─── Identity ────────────────────────────────────────────────────────────────

variable "workspace_id" {
  type        = string
  description = "Fabric workspace ID where the Data Pipeline will be created."
}

variable "display_name" {
  type        = string
  description = "Display name shown in the Fabric Portal."
}

variable "description" {
  type        = string
  description = "Description shown in the Fabric Portal."
  default     = "Control table driven pipeline: PostgreSQL → Lakehouse raw files (parquet) with full logging"
}

# ─── Pipeline parameters (defaults shown in Fabric Portal run dialog) ────────

variable "pipeline_name_param_default" {
  type        = string
  description = "Default value for the pipeline_name parameter, used to filter app.pipeline_control rows."
  default     = ""
}

variable "environment" {
  type        = string
  description = "Default value for the environment parameter, written to app.pipeline_log (e.g. DEV, TEST, PROD)."
  default     = "DEV"
}

variable "triggered_by_default" {
  type        = string
  description = "Default value for the triggered_by parameter, written to app.pipeline_log. Replaces unsupported pipeline().TriggerName."
  default     = "manual"
}

# ─── Warehouse connection (for Lookup + Script activities) ───────────────────
# Script activities and the Lookup activity reach the warehouse via the
# connection GUID only — no linkedService, artifactId, or endpoint required
# in Fabric pipeline JSON.

variable "warehouse_connection_id" {
  type        = string
  description = "Fabric connection ID for the warehouse holding app.pipeline_control and app.pipeline_log."
}

# ─── Source: PostgreSQL connection ───────────────────────────────────────────

variable "source_connection_id" {
  type        = string
  description = "Fabric connection ID for the PostgreSQL source. Used for all tables driven by the control table."
}

# ─── Sink: Fabric Lakehouse (Files area for raw parquet output) ─────────────

variable "lakehouse_name" {
  type        = string
  description = "Display name of the destination Fabric Lakehouse."
}

variable "lakehouse_id" {
  type        = string
  description = "Artifact ID of the destination Fabric Lakehouse."
}

# ─── Execution ───────────────────────────────────────────────────────────────

variable "parallel_copies" {
  type        = number
  description = "Max number of tables to copy in parallel within the same ForEach batch."
  default     = 10
}

variable "activity_timeout" {
  type        = string
  description = "Timeout per Copy / Lookup activity in d.HH:MM:SS format."
  default     = "0.12:00:00"
}

variable "activity_retry" {
  type        = number
  description = "Number of retry attempts per activity on failure."
  default     = 0
}
