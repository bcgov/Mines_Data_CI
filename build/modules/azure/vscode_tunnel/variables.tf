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

###############################################################################
# Networking
###############################################################################

variable "subnet_id" {
  description = "Subnet ID with Microsoft.ContainerInstance/containerGroups delegation."
  type        = string
}

###############################################################################
# ARM credentials
# Injected into the VS Code tunnel container so az login works once connected.
###############################################################################

variable "arm_client_id" {
  description = "Service principal client ID."
  type        = string
  sensitive   = true
}

variable "arm_client_secret" {
  description = "Service principal client secret."
  type        = string
  sensitive   = true
}

variable "arm_tenant_id" {
  description = "Azure AD tenant ID."
  type        = string
  sensitive   = true
}

variable "arm_subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

###############################################################################
# VS Code Tunnel
###############################################################################

variable "tunnel_name" {
  description = "Name for the VS Code tunnel. Appears in VS Code Remote Explorer."
  type        = string
  default     = "mines-jumpbox"
}

variable "tunnel_cpu" {
  description = "CPU cores for the VS Code tunnel container."
  type        = number
  default     = 1
}

variable "tunnel_memory" {
  description = "Memory in GB for the VS Code tunnel container."
  type        = number
  default     = 2
}

###############################################################################
# GitHub Actions Runner
###############################################################################

variable "github_pat" {
  description = "GitHub PAT with repo scope for runner registration."
  type        = string
  sensitive   = true
}

variable "github_repo" {
  description = "GitHub repo to register the runner against. Format: 'owner/repo'."
  type        = string
}

variable "runner_name" {
  description = "Display name for the self-hosted runner in GitHub."
  type        = string
  default     = "mines-aci-runner"
}

variable "runner_labels" {
  description = "Comma-separated labels for the runner."
  type        = string
  default     = "self-hosted,linux,azure,private-vnet"
}

variable "runner_cpu" {
  description = "CPU cores for the GitHub Actions runner container."
  type        = number
  default     = 1
}

variable "runner_memory" {
  description = "Memory in GB for the GitHub Actions runner container."
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
  description = "Additional sensitive environment variables for the tunnel container."
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
