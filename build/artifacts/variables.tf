variable "ARM_TENANT_ID" {
  description = "Azure Tenant ID"
  type        = string
  default     = null
}

variable "ARM_CLIENT_ID" {
  description = "Azure Client ID"
  type        = string
}

variable "ARM_CLIENT_SECRET" {
  description = "Azure Client Secret"
  type        = string
  sensitive   = true
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "Azure Subscription ID"
  type        = string
  default     = null
}

variable "ENVIRONMENT" {
  description = "Environment name"
  type        = string
  default     = "test"
}


variable "GITHUB_PAT" {
  description = "GitHub Personal Access Token with repo scope. Used by the vscode_tunnel container to register the self-hosted GitHub Actions runner at startup. Set via GitHub secret GITHUB_PAT."
  type        = string
  sensitive   = true
}