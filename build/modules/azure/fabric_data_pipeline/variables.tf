# ─── Identity ───────────────────────────────────────────────────────────────

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
  default     = "On-demand Data Pipeline: PostgreSQL → Lakehouse raw files (parquet)"
}

# ─── Source: PostgreSQL ──────────────────────────────────────────────────────

variable "source_connection_id" {
  type        = string
  description = "Fabric connection ID for the PostgreSQL source."
}

variable "source_database" {
  type        = string
  description = "PostgreSQL database name (e.g. 'mds')."
}

variable "source_schema" {
  type        = string
  description = "PostgreSQL source schema (e.g. 'public')."
  default     = "public"
}

# ─── Sink: Fabric Lakehouse Files ───────────────────────────────────────────

variable "lakehouse_name" {
  type        = string
  description = "Display name of the destination Fabric Lakehouse."
}

variable "lakehouse_id" {
  type        = string
  description = "Artifact ID of the destination Fabric Lakehouse."
}

# ─── Table mappings ──────────────────────────────────────────────────────────

variable "table_mappings" {
  type = list(object({
    source_table = string
    sink_table   = string
  }))
  description = "List of {source_table, sink_table} pairs. Files land at raw/<source_table>/yyyy/mm/dd/<source_table>_<timestamp>.parquet"

  validation {
    condition     = length(var.table_mappings) > 0
    error_message = "At least one table mapping is required."
  }
}

# ─── Activity policy ─────────────────────────────────────────────────────────

variable "activity_timeout" {
  type        = string
  description = "Activity timeout in d.HH:MM:SS format."
  default     = "0.12:00:00"
}

variable "activity_retry" {
  type        = number
  description = "Number of retry attempts on failure."
  default     = 0
}
