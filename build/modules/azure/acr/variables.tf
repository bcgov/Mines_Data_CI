# modules/acr/variables.tf

variable "instance_number" {
  type        = string
  description = "Instance number suffix for resource naming"
  default     = "00"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "fabric"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "-"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "suffix" {
  type        = string
  description = "Resource name suffix"
  default     = "acr"
}

variable "acr_name" {
  description = "Override for the ACR name. If null, name is auto-generated. Must be alphanumeric only, 5-50 chars."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the ACR"
  type        = string
}

variable "location" {
  description = "The Azure region where the ACR should be created"
  type        = string
  default     = "eastus2"
}

variable "sku" {
  description = "The SKU tier for the ACR. Options: Basic, Standard, Premium. Premium is required for private endpoints and geo-replication."
  type        = string
  default     = "Premium"
}

variable "admin_enabled" {
  description = "Whether the admin user is enabled for the ACR. Not recommended for production — use RBAC instead."
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled for the ACR."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled for the ACR. Only supported on Premium SKU."
  type        = bool
  default     = false
}

variable "data_endpoint_enabled" {
  description = "Whether to enable dedicated data endpoints for the ACR. Only supported on Premium SKU."
  type        = bool
  default     = false
}

###############################################################################
# Identity
###############################################################################

variable "identity_type" {
  description = "The type of Managed Identity assigned to the ACR. Options: SystemAssigned, UserAssigned, SystemAssigned, UserAssigned."
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "List of User Assigned Managed Identity IDs to assign to the ACR. Required when identity_type includes UserAssigned."
  type        = list(string)
  default     = []
}

variable "managed_identity_delegate" {
  description = "Object ID of a managed identity or service principal to grant AcrPush on the registry. Defaults to the current client."
  type        = string
  default     = null
}

###############################################################################
# RBAC
###############################################################################

variable "enable_rbac_assignments" {
  description = "Whether to create role assignments for the deploying identity. Disable if the Service Principal lacks Microsoft.Authorization/roleAssignments/write."
  type        = bool
  default     = false
}

variable "additional_access_policies" {
  description = "List of additional RBAC role assignments. role_definition_name should be a built-in ACR role e.g. 'AcrPull', 'AcrPush', 'AcrDelete', 'Contributor'."
  type = list(object({
    object_id            = string
    role_definition_name = string
  }))
  default = []
}

###############################################################################
# Network rules
###############################################################################

variable "ip_rules" {
  description = "List of IP ranges (CIDR) allowed to access the ACR when public_network_access_enabled is true. Requires Premium SKU."
  type        = list(string)
  default     = []
}

###############################################################################
# Private Endpoint
###############################################################################

variable "private_endpoint_enabled" {
  description = "Whether to create a private endpoint for the ACR. Requires Premium SKU."
  type        = bool
  default     = true
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID where the ACR private endpoint will be created."
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "Private DNS Zone IDs for ACR (privatelink.azurecr.io). Optional."
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

###############################################################################
# Tagging
###############################################################################

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default = {
    "ministry_name_prefix"                = "citz"
    "program_area"                        = "permitting"
    "client_code"                         = ""
    "responsibility_centre"               = ""
    "service_line"                        = ""
    "project_number"                      = ""
    "expense_authority"                   = ""
    "deployment_automation"               = "Terraform"
    "deployment_automation_version"       = "v0.1"
    "application_environment"             = "dev"
    "information_security_classification" = "protected_e"
  }
}
