variable "prefix" {
  description = "Prefix for the workspace name."
  type        = string
}

variable "project" {
  description = "Project name for the workspace."
  type        = string
}

variable "instance_number" {
  description = "Instance number for the workspace."
  type        = number
  default     = 1
}

variable "workspace_name" {
  description = "Optional workspace name to override the default naming convention."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Fabric Workspace."
  type        = string
  default     = "Default Workspace Description"
}

variable "capacity_id" {
  description = "ID of the Fabric Capacity to assign to the workspace."
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Timeout settings for the Fabric Workspace resource."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}

# variable "identity_type" {
#   description = "The type of identity to assign to the workspace. Accepted values: SystemAssigned."
#   type        = string
#   default     = "SystemAssigned"
# }

variable "identity_type" {
  description = "Type of identity to assign. Only SystemAssigned is allowed. Empty string disables identity."
  type        = string
  default     = ""

  validation {
    condition     = var.identity_type == "" || var.identity_type == "SystemAssigned"
    error_message = "identity_type must be 'SystemAssigned' or empty string."
  }
}


# Variables for Fabric Workspace Git Integration
variable "enable_git_integration" {
  description = "Flag to enable Fabric Workspace Git integration."
  type        = bool
  default     = false
}

variable "git_initialization_strategy" {
  description = "The initialization strategy for Git integration. Accepted values: PreferRemote, PreferWorkspace."
  type        = string
  default     = null
}

variable "git_provider_details" {
  description = "Git provider details for Fabric Workspace Git integration."
  type = object({
    git_provider_type = string
    organization_name = string
    project_name      = string
    repository_name   = string
    branch_name       = string
    directory_name    = string
  })
  default = null
}

variable "timeouts_git" {
  description = "Timeout settings for the Fabric Workspace Git Integration resource."
  type = object({
    create = optional(string)
    read   = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = {}
}

variable "owners" {
  description = "List of user principal names (emails) to grant Admin on the Fabric Workspace."
  type        = list(string)
  default     = []
}

variable "env" {
  description = "Environment name for the Fabric Workspace."
  type        = string
  default     = "dev"
}