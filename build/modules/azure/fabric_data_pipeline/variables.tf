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
  default     = "Control table driven pipeline: PostgreSQL → Lakehouse raw files (parquet) with full logging"
}

variable "pipeline_name_param_default" {
  type        = string
  description = "Default value for the pipeline_name parameter shown in the Fabric Portal run dialog."
  default     = ""
}

# ─── Control table + logging: Fabric Warehouse ───────────────────────────────

variable "sink_warehouse_id" {
  type        = string
  description = "Artifact ID of the Fabric Warehouse holding app.pipeline_control and app.pipeline_log."
}

variable "sink_warehouse_name" {
  type        = string
  description = "Display name of the Fabric Warehouse."
  default     = "mines-data-platform-fabwh1"
}

variable "sink_endpoint" {
  type        = string
  description = "Fabric Warehouse SQL endpoint hostname."
  default     = "abjnw3ynhwfevmbw2nuf4nm23q-rahtrd7fltiurh5f7o734jufua.datawarehouse.fabric.microsoft.com"
}


variable "warehouse_connection_id" {
  type        = string
  description = "Fabric connection ID for the warehouse (from Manage connections and gateways). Used by Script and Lookup activities to connect to app.pipeline_control and app.pipeline_log."
}

# ─── Source: PostgreSQL connection ───────────────────────────────────────────

variable "source_connection_id" {
  type        = string
  description = "Fabric connection ID for the PostgreSQL source. Used for all tables driven by the control table."
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


variable "environment" {
  type        = string
  description = "Environment name written to app.pipeline_log (e.g. DEV, TEST, PROD)."
  default     = "DEV"
}

# ─── Execution ───────────────────────────────────────────────────────────────

variable "parallel_copies" {
  type        = number
  description = "Max number of tables to copy in parallel within the same ForEach batch."
  default     = 10
}

variable "activity_timeout" {
  type        = string
  description = "Timeout per Copy activity in d.HH:MM:SS format."
  default     = "0.12:00:00"
}

variable "activity_retry" {
  type        = number
  description = "Number of retry attempts per activity on failure."
  default     = 0
}
