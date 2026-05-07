# modules/azure/vscode_tunnel/variables.tf

variable "instance_number" {
  type        = string
  description = "Instance number suffix for resource naming"
  default     = "01"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "fabric"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "name" {
  description = "Override for the container group name. If null, name is auto-generated."
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group to deploy the container group into."
  type        = string
}

variable "location" {
  description = "Azure region for the container group."
  type        = string
  default     = "canadacentral"
}

variable "subnet_id" {
  description = "Subnet ID with Microsoft.ContainerInstance/containerGroups delegation."
  type        = string
}

###############################################################################
# Tunnel
###############################################################################

variable "tunnel_name" {
  description = "Name for the VS Code tunnel. Appears in VS Code Remote Explorer."
  type        = string
  default     = "mines-jumpbox"
}

variable "cpu" {
  description = "CPU cores for the tunnel container."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in GB for the tunnel container."
  type        = number
  default     = 2
}

###############################################################################
# Environment
###############################################################################

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "key_vault_uri" {
  description = "Key Vault URI injected as KEY_VAULT_URI env var."
  type        = string
  default     = ""
}

variable "extra_environment_variables" {
  description = "Additional plain-text environment variables for the tunnel container."
  type        = map(string)
  default     = {}
}

variable "secure_environment_variables" {
  description = <<-EOT
    Sensitive environment variables injected into the tunnel container.
    These are encrypted at rest in Azure and never shown in the portal.

    IMPORTANT: Do NOT source these from Terraform input variables (TF_VAR_*)
    as that writes them to terraform.tfstate in plaintext.
    Instead, read them from Key Vault using a data source:

      data "azurerm_key_vault_secret" "arm_secret" {
        name         = "arm-client-secret"
        key_vault_id = module.key_vault_adf.kv_id
      }

      secure_environment_variables = {
        ARM_CLIENT_SECRET = data.azurerm_key_vault_secret.arm_secret.value
      }
  EOT
  type        = map(string)
  default     = {}
  sensitive   = true
}

###############################################################################
# Tagging
###############################################################################

variable "tags" {
  description = "Tags to apply to all resources."
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
