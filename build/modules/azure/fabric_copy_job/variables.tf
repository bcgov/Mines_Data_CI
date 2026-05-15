# ─── Identity ───────────────────────────────────────────────────────────────

variable "workspace_id" {
  type        = string
  description = "Fabric workspace ID where the Copy Job will be created."
}

variable "display_name" {
  type        = string
  description = "Display name shown in the Fabric Portal."
}

variable "description" {
  type        = string
  description = "Description shown in the Fabric Portal."
  default     = "On-demand Copy Job to Fabric Warehouse"
}

# ─── Source ─────────────────────────────────────────────────────────────────

variable "source_type" {
  type        = string
  description = "Source connector type. One of: PostgreSql, Oracle."

  validation {
    condition     = contains(["PostgreSql", "Oracle", "PostgreSQL", "ORACLE"], var.source_type)
    error_message = "source_type must be PostgreSql or Oracle."
  }
}

variable "source_connection_id" {
  type        = string
  description = "Fabric connection ID — typically the output of the fabric_connection module."
}

variable "source_database" {
  type        = string
  description = "Source database name."
}

variable "source_schema" {
  type        = string
  description = "Source schema. For PostgreSQL typically 'public'; for Oracle this is the schema/user owning the tables."
  default     = "public"
}

# ─── Sink: Fabric Warehouse ─────────────────────────────────────────────────

variable "sink_workspace_id" {
  type        = string
  description = "Workspace ID of the destination Fabric Warehouse (often the same as workspace_id)."
}

variable "sink_warehouse_id" {
  type        = string
  description = "Fabric Warehouse artifact ID (destination)."
}

variable "sink_schema" {
  type        = string
  description = "Destination schema in the warehouse (e.g. 'bronze')."
  default     = "bronze"
}


variable "table_option" {
  type        = string
  description = "Behaviour when target table doesn't exist. 'autoCreate' creates it from the source schema; 'useExistingTable' requires it to exist already."
  default     = "autoCreate"

  validation {
    condition     = contains(["autoCreate", "useExistingTable"], var.table_option)
    error_message = "table_option must be autoCreate or useExistingTable."
  }
}

# ─── Table mappings ─────────────────────────────────────────────────────────

variable "table_mappings" {
  type = list(object({
    source_table = string
    sink_table   = string
  }))
  description = "List of {source_table, sink_table} pairs. Each pair creates one table-to-table copy operation."

  validation {
    condition     = length(var.table_mappings) > 0
    error_message = "At least one table mapping is required."
  }
}
