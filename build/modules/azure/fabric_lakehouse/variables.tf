variable "prefix" {
  description = "Prefix for the lakehouse name."
  type        = string
}

variable "project" {
  description = "Project name for the lakehouse."
  type        = string
}

variable "instance_number" {
  description = "Instance number for the lakehouse."
  type        = number
  default     = 1
}

variable "lakehouse_name" {
  description = "Optional lakehouse name to override the default naming convention."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Fabric Lakehouse."
  type        = string
  default     = "Default Lakehouse Description"
}

variable "workspace_id" {
  description = "ID of the Fabric Workspace to create the lakehouse in."
  type        = string
}

variable "enable_schemas" {
  description = "Enable schema support on the lakehouse. WARNING: changing this after creation forces recreation of the lakehouse."
  type        = bool
  default     = false
}

variable "schemas" {
  description = "List of schema names to create in the lakehouse. Requires enable_schemas = true."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.schemas) == 0 || var.enable_schemas == true
    error_message = "schemas can only be set when enable_schemas is true."
  }
}

variable "timeouts" {
  description = "Timeout settings for the Fabric Lakehouse resource."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}
