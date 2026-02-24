variable "instance_number" {
  type        = string
  description = "Instance number"
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
  default     = "dev"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
}

variable "suffix" {
  type        = string
  description = "Resource name suffix"
  default     = "vnet"
}

variable "vnet_name" {
  description = "Optional override for the VNet name"
  type        = string
  default     = null
}

variable "resource_group_name" {
  description = "Resource group to deploy the VNet into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "canadacentral"
}

variable "address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create"
  type = map(object({
    address_prefixes                  = list(string)
    private_endpoint_network_policies = optional(string, "Enabled")
    service_endpoints                 = optional(list(string), [])
  }))
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