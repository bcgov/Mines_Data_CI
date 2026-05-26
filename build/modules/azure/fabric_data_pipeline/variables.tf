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
  default     = "On-demand Data Pipeline: PostgreSQL → Fabric Warehouse"
}

# ─── Source: PostgreSQL connection ───────────────────────────────────────────

variable "source_connection_id" {
  type        = string
  description = "Fabric connection ID for the PostgreSQL source. Must already exist in Fabric Portal."
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

# ─── Sink: Fabric Warehouse ──────────────────────────────────────────────────

variable "sink_workspace_id" {
  type        = string
  description = "Workspace ID of the destination Fabric Warehouse."
}

variable "sink_warehouse_id" {
  type        = string
  description = "Fabric Warehouse artifact ID (destination)."
}

variable "sink_schema" {
  type        = string
  description = "Destination schema in the Fabric Warehouse (e.g. 'bronze')."
  default     = "bronze"
}

# ─── Table mappings ──────────────────────────────────────────────────────────

variable "table_mappings" {
  type = list(object({
    source_table = string
    sink_table   = string
  }))
  description = "List of {source_table, sink_table} pairs. Each generates one Copy activity in the pipeline."

  validation {
    condition     = length(var.table_mappings) > 0
    error_message = "At least one table mapping is required."
  }
}

# ─── Copy behaviour ──────────────────────────────────────────────────────────

variable "write_behavior" {
  type        = string
  description = "How data is written to the warehouse. 'insert' appends rows; 'upsert' merges on key."
  default     = "insert"

  validation {
    condition     = contains(["insert", "upsert"], var.write_behavior)
    error_message = "write_behavior must be insert or upsert."
  }
}

variable "table_option" {
  type        = string
  description = "'autoCreate' creates the sink table if it doesn't exist. 'none' requires the table to already exist."
  default     = "autoCreate"

  validation {
    condition     = contains(["autoCreate", "none"], var.table_option)
    error_message = "table_option must be autoCreate or none."
  }
}

variable "allow_data_truncation" {
  type        = bool
  description = "Allow truncation when source value is larger than sink column definition."
  default     = true
}

variable "enable_staging" {
  type        = bool
  description = "Enable staging (required for on-premises sources writing to Fabric Warehouse). Uses an external Azure Storage staging account."
  default     = false
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
