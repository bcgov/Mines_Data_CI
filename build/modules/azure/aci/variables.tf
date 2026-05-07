# modules/aci/variables.tf

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
  default     = "aci"
}

variable "aci_name" {
  description = "Override for the container group name. If null, name is auto-generated."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the ACI"
  type        = string
}

variable "location" {
  description = "The Azure region where the ACI should be created"
  type        = string
  default     = "eastus2"
}

###############################################################################
# Managed Identity
###############################################################################

variable "create_managed_identity" {
  description = "Whether to create a new User Assigned Managed Identity for the ACI. If false, provide user_assigned_identity_id and managed_identity_principal_id."
  type        = bool
  default     = true
}

variable "user_assigned_identity_id" {
  description = "Resource ID of an existing User Assigned Managed Identity. Used when create_managed_identity = false."
  type        = string
  default     = null
}

variable "managed_identity_principal_id" {
  description = "Principal ID of the existing User Assigned Managed Identity. Used when create_managed_identity = false."
  type        = string
  default     = null
}

###############################################################################
# RBAC
###############################################################################

variable "enable_rbac_assignments" {
  description = "Whether to create role assignments (AcrPull, Key Vault Secrets User) for the ACI identity. Disable if the Service Principal lacks Microsoft.Authorization/roleAssignments/write."
  type        = bool
  default     = true
}

variable "acr_id" {
  description = "Resource ID of the ACR to grant AcrPull to the ACI managed identity. Optional."
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to grant Key Vault Secrets User to the ACI managed identity. This enables the jumpbox to read secrets without local access."
  type        = string
  default     = null
}

variable "additional_access_policies" {
  description = "List of additional RBAC role assignments to create. Each entry requires object_id, role_definition_name, and scope."
  type = list(object({
    object_id            = string
    role_definition_name = string
    scope                = string
  }))
  default = []
}

###############################################################################
# Container Group
###############################################################################

variable "os_type" {
  description = "The OS type for the container group. Options: Linux, Windows."
  type        = string
  default     = "Linux"
}

variable "restart_policy" {
  description = "Restart policy for the container group. Options: Always, Never, OnFailure."
  type        = string
  default     = "Never" # Jumpbox — spin up on demand, don't auto-restart
}

variable "vnet_mode" {
  description = <<-EOT
    Set to true when deploying the container group into a VNet (i.e. subnet_id is provided).
    Must be set explicitly as a literal bool — do NOT derive this from a computed value.
    This is required because Terraform resolves count/for_each before apply, and a computed
    subnet_id would cause an "Invalid count argument" error.
    When true: ip_address_type = Private, managed identity is disabled (Azure limitation),
    ACR pull falls back to admin username/password.
  EOT
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID to deploy the container group into (VNet integration). Required to reach private endpoints for Key Vault and ACR."
  type        = string
  default     = null
}

###############################################################################
# ACR integration
###############################################################################

variable "acr_login_server" {
  description = "Login server of the ACR (e.g. myregistry.azurecr.io). Used to configure image pull credentials via managed identity."
  type        = string
  default     = null
}

variable "acr_username" {
  description = "ACR admin username for image pull when deployed into a VNet (managed identity is not supported in VNet-injected container groups). Only used when subnet_id is set."
  type        = string
  default     = null
}

variable "acr_password" {
  description = "ACR admin password for image pull when deployed into a VNet. Only used when subnet_id is set. Mark as sensitive in your tfvars."
  type        = string
  default     = null
  sensitive   = true
}

###############################################################################
# Container definition
###############################################################################

variable "container_command" {
  description = "Command to run in the container. Use [\"/bin/sh\", \"-c\", \"tail -f /dev/null\"] to keep a jumpbox alive indefinitely."
  type        = list(string)
  default     = ["/bin/sh", "-c", "tail -f /dev/null"]
}

variable "container_name" {
  description = "Name of the jumpbox container instance."
  type        = string
  default     = "jumpbox"
}

variable "container_image" {
  description = "Full image reference for the jumpbox container (e.g. myregistry.azurecr.io/jumpbox:latest or mcr.microsoft.com/azure-cli:latest)."
  type        = string
  default     = "mcr.microsoft.com/azure-cli:latest"
}

variable "cpu" {
  description = "Number of CPU cores allocated to the jumpbox container."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in GB allocated to the jumpbox container."
  type        = number
  default     = 1.5
}

variable "container_ports" {
  description = "List of ports to expose on the container. Leave empty for an outbound-only jumpbox."
  type = list(object({
    port     = number
    protocol = string
  }))
  default = [] # Jumpbox doesn't need inbound ports
}

###############################################################################
# Environment variables
###############################################################################

variable "environment_variables" {
  description = "Map of plain-text environment variables to inject into the container (e.g. KEY_VAULT_URI, ACR_NAME)."
  type        = map(string)
  default     = {}
}

variable "secure_environment_variables" {
  description = "Map of sensitive environment variables to inject into the container. Values are marked sensitive in state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

###############################################################################
# Volume mounts
###############################################################################

variable "volumes" {
  description = "List of Azure File Share volumes to mount into the container."
  type = list(object({
    name                 = string
    mount_path           = string
    read_only            = optional(bool, false)
    share_name           = optional(string)
    storage_account_name = optional(string)
    storage_account_key  = optional(string)
  }))
  default = []
}

###############################################################################
# Liveness probe
###############################################################################

variable "liveness_probe_exec" {
  description = "Command to run as the liveness probe (e.g. [\"/bin/sh\", \"-c\", \"exit 0\"]). Leave empty to disable."
  type        = list(string)
  default     = []
}

variable "liveness_probe_initial_delay" {
  description = "Initial delay in seconds before the liveness probe starts."
  type        = number
  default     = 10
}

variable "liveness_probe_period" {
  description = "How often (in seconds) the liveness probe runs."
  type        = number
  default     = 30
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
