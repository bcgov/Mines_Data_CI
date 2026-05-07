variable "prefix" {
  description = "Prefix for the pipeline name."
  type        = string
}

variable "project" {
  description = "Project name for the pipeline."
  type        = string
}

variable "instance_number" {
  description = "Instance number for the pipeline."
  type        = number
  default     = 1
}

variable "pipeline_name" {
  description = "Optional pipeline name to override the default naming convention."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Fabric Data Pipeline."
  type        = string
  default     = "Default Data Pipeline Description"
}

variable "workspace_id" {
  description = "ID of the Fabric Workspace to create the pipeline in."
  type        = string
}


variable "timeouts" {
  description = "Timeout settings for the Fabric Data Pipeline resource."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}
