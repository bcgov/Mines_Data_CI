variable "prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "project" {
  description = "Project name."
  type        = string
}

variable "instance_number" {
  description = "Instance number for the resource."
  type        = number
  default     = 1
}

variable "description" {
  description = "Description of the Fabric Workspace."
  type        = string
  default     = ""
}

variable "workspace_id" {
  description = "id of fabric workspace."
  type        = string
  default     = null
}

variable "fabric_warehouse" {
  description = "Name of fabric warehouse."
  type        = string
  default     = null
}
