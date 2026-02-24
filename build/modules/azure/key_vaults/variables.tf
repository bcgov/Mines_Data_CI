# modules/key_vaults/variables.tf

variable "Instance_Number" {
  type        = string
  description = "Project name"
  default = "00"
}

variable "project" {
  type        = string
  description = "Project name"
  default = "fabric"
}

variable "env" {
  type        = string
  description = "Environment name"
  default = "-"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "suffix" {
  type        = string
  description = "Resource name suffix"
  default     = "kv"
}

variable "key_vault_name" {
  description = "The name of the Key Vault"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Key Vault"
  type        = string
}

variable "location" {
  description = "The location where the Key Vault should be created"
  type        = string
  default     = "eastus2"
}

variable "sku_family" {
  description = "The SKU family of the Key Vault"
  type        = string
  default     = "A"
}

variable "sku_name" {
  description = "The SKU name of the Key Vault"
  type        = string
  default     = "standard"
}

variable "enabled_for_disk_encryption" {
  description = "Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault"
  type        = bool
  default     = false
}

variable "certificate_permissions" {
  description = "List of certificate permissions"
  type        = list(string)
  default     = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
}

variable "key_permissions" {
  description = "List of key permissions"
  type        = list(string)
  default     = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"]
}

variable "secret_permissions" {
  description = "List of secret permissions"
  type        = list(string)
  default     = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
}

variable "storage_permissions" {
  description = "List of secret permissions"
  type        = list(string)
  default = [
    "Get",
    "Backup",
    "Delete",
    "DeleteSAS",
    "GetSAS",
    "List",
    "ListSAS",
    "Purge",
    "Recover",
    "RegenerateKey",
    "Restore",
    "Set",
    "SetSAS",
    "Update"
  ]
}

variable "purge_protection_enabled" {
  description = "Protect KV from purge "
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Protect KV from purge "
  type        = number
  default     = 7
}


variable "managed_identity_delegate" {
  description = "Id of the managed identity to give access to the keyvault"
  type        = string
  default     = null
}


variable  "public_network_access_enabled" {
  description = "specifies if the kv should be publicly available on network"
  type = bool
  default = false
}
variable "virtual_network_subnet_ids" {
  description = "One or more Subnet IDs which should be able to access this Key Vault."
  type        = list(string)
  default     = []
}
variable "ip_rules" {
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault when public network access is enabled."
  type        = list(string)
  default     = []
}

###############################################################################
# Additional KV access policies (users/groups/SPs)
###############################################################################
variable "additional_access_policies" {
  description = "List of additional RBAC role assignments. role_definition_name should be a built-in KV role e.g. 'Key Vault Secrets User', 'Key Vault Secrets Officer', 'Key Vault Crypto Officer', 'Key Vault Administrator'."
  type = list(object({
    object_id            = string
    role_definition_name = string
  }))
  default = []
}

###############################################################################
# Key Vault Private Endpoint
###############################################################################
variable "private_endpoint_enabled" {
  description = "Whether to create a private endpoint for the Key Vault."
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID where the KV private endpoint will be created."
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS Zone IDs for Key Vault (privatelink.vaultcore.azure.net). Optional."
  type        = list(string)
  default     = []
}

variable "private_endpoint_name" {
  description = "Optional override for private endpoint name."
  type        = string
  default     = null
}

variable "private_service_connection_name" {
  description = "Optional override for private service connection name."
  type        = string
  default     = null
}

# tagging variables #
variable "tags" {
  description = "Tags to apply to the Azure Resource Group"
  type        = map(string)
  default = {
    "ministry_name_prefix"                          = "citz"
    "program_area"                                  = "permitting"
    "client_code"                                   = ""
    "responsibility_centre"                         = ""
    "service_line"                                  = ""
    "project_number"                                = ""
    "expense_authority"                             = ""
    "deployment_automation"                         = "Terraform"
    "deployment_automation_version"                 = "v0.1"
    "application_environment"                       = "dev"
    "information_security_classification"           = "protected_e"
  }
}