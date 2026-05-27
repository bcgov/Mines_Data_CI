# ─── Identity ───────────────────────────────────────────────────────────────

variable "display_name" {
  type        = string
  description = "Display name of the connection (shown in Fabric Portal)."
}

# ─── Connection type ────────────────────────────────────────────────────────

variable "connection_type" {
  type        = string
  description = "Source system type. One of: PostgreSQL, Oracle, Warehouse."

  validation {
    condition     = contains(["PostgreSQL", "Oracle", "Warehouse"], var.connection_type)
    error_message = "connection_type must be one of: PostgreSQL, Oracle, Warehouse."
  }
}

# ─── Connectivity ───────────────────────────────────────────────────────────

variable "connectivity_type" {
  type        = string
  description = "Connection routing. ShareableCloud = public Fabric IR. VirtualNetworkGateway / OnPremisesGateway require a gateway_id."
  default     = "ShareableCloud"

  validation {
    condition     = contains(["ShareableCloud", "VirtualNetworkGateway", "OnPremisesGateway"], var.connectivity_type)
    error_message = "connectivity_type must be ShareableCloud, VirtualNetworkGateway, or OnPremisesGateway."
  }
}

variable "gateway_id" {
  type        = string
  description = "Gateway GUID (required when connectivity_type is not ShareableCloud)."
  default     = null
}

# ─── Warehouse-specific ──────────────────────────────────────────────────────

variable "workspace_id" {
  type        = string
  description = "Fabric workspace ID. Required for Warehouse connections."
  default     = null
}

variable "warehouse_id" {
  type        = string
  description = "Fabric Warehouse artifact ID. Required for Warehouse connections."
  default     = null
}

# ─── Server / database ──────────────────────────────────────────────────────

variable "server" {
  type        = string
  description = "Hostname or IP of the source server. Not required for Warehouse connections."
  default     = null
}

variable "database" {
  type        = string
  description = "Database name to connect to. Not required for Warehouse connections."
  default     = null
}

variable "port" {
  type        = number
  description = "Port (Oracle only — leave null to use the default 1521 listener)."
  default     = null
}

# ─── Credentials ────────────────────────────────────────────────────────────

variable "username" {
  type        = string
  description = "Username for Basic authentication. Not required for Warehouse connections."
  sensitive   = true
  default     = null
}

variable "password" {
  type        = string
  description = "Password for Basic authentication. Not required for Warehouse connections. Never stored in state (write-only)."
  sensitive   = true
  default     = null
}

variable "password_version" {
  type        = number
  description = "Increment this to rotate the password through Terraform."
  default     = 1
}

# ─── Security / behaviour ───────────────────────────────────────────────────

variable "privacy_level" {
  type        = string
  description = "Power Query privacy level."
  default     = "Organizational"

  validation {
    condition     = contains(["None", "Private", "Organizational", "Public"], var.privacy_level)
    error_message = "privacy_level must be None, Private, Organizational, or Public."
  }
}

variable "connection_encryption" {
  type        = string
  description = "Encryption mode for the connection itself."
  default     = "Encrypted"

  validation {
    condition     = contains(["Any", "Encrypted", "NotEncrypted"], var.connection_encryption)
    error_message = "connection_encryption must be Any, Encrypted, or NotEncrypted."
  }
}

variable "skip_test_connection" {
  type        = bool
  description = "Skip the connection test during create/update."
  default     = false
}
