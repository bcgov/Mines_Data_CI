# ─── Identity ───────────────────────────────────────────────────────────────

variable "display_name" {
  type        = string
  description = "Display name of the connection (shown in Fabric Portal)."
}

# ─── Connection type ────────────────────────────────────────────────────────

variable "connection_type" {
  type        = string
  description = "Source system type. One of: PostgreSQL, Oracle."

  validation {
    condition     = contains(["PostgreSQL", "Oracle"], var.connection_type)
    error_message = "connection_type must be one of: PostgreSQL, Oracle."
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

# ─── Server / database ──────────────────────────────────────────────────────

variable "server" {
  type        = string
  description = "Hostname or IP of the source server (e.g. 'mds-reporting-pg13-live.postgres.database.azure.com')."
}

variable "database" {
  type        = string
  description = "Database name to connect to."
}

variable "port" {
  type        = number
  description = "Port (Oracle only — leave null to use the default 1521 listener)."
  default     = null
}

# ─── Credentials ────────────────────────────────────────────────────────────

variable "username" {
  type        = string
  description = "Username for Basic authentication."
  sensitive   = true
}

variable "password_keyvault_id" {
  type        = string
  description = "Resource ID of the Azure Key Vault holding the password secret. Format: /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>"
}

variable "password_secret_name" {
  type        = string
  description = "Name of the secret in Key Vault that holds the password."
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
  description = "Skip the connection test during create/update (useful if firewalls block the test but allow runtime)."
  default     = false
}
