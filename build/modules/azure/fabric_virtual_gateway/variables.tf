variable "prefix" {
  description = "Prefix for the gateway name."
  type        = string
}

variable "project" {
  description = "Project name for the gateway."
  type        = string
}

variable "instance_number" {
  description = "Instance number for the gateway."
  type        = number
  default     = 1
}

variable "gateway_name" {
  description = "Optional gateway name to override the default naming convention."
  type        = string
  default     = null
}

variable "capacity_id" {
  description = "ID of the Fabric Capacity to assign to the Virtual Network Gateway. Required for VirtualNetwork type."
  type        = string
}

variable "inactivity_minutes_before_sleep" {
  description = "Number of minutes of inactivity before the gateway goes to sleep. Must be between 30 and 1440."
  type        = number
  default     = 30

  validation {
    condition     = var.inactivity_minutes_before_sleep >= 30 && var.inactivity_minutes_before_sleep <= 1440
    error_message = "inactivity_minutes_before_sleep must be between 30 and 1440."
  }
}

variable "number_of_member_gateways" {
  description = "Number of member gateways. Must be between 1 and 7."
  type        = number
  default     = 1

  validation {
    condition     = var.number_of_member_gateways >= 1 && var.number_of_member_gateways <= 7
    error_message = "number_of_member_gateways must be between 1 and 7."
  }
}

variable "virtual_network_azure_resource" {
  description = "Azure Virtual Network resource details for the gateway. All fields are required."
  type = object({
    resource_group_name  = string
    virtual_network_name = string
    subnet_name          = string
    subscription_id      = string
  })
}

variable "allow_cloud_connection_refresh" {
  description = "Allow cloud connection refresh on the gateway."
  type        = bool
  default     = false
}

variable "allow_custom_connectors" {
  description = "Allow custom connectors on the gateway."
  type        = bool
  default     = false
}

variable "load_balancing_setting" {
  description = "Load balancing setting for the gateway. Accepted values: DistributeEvenly, Failover."
  type        = string
  default     = "DistributeEvenly"

  validation {
    condition     = contains(["DistributeEvenly", "Failover"], var.load_balancing_setting)
    error_message = "load_balancing_setting must be one of: DistributeEvenly, Failover."
  }
}

variable "timeouts" {
  description = "Timeout settings for the Fabric Virtual Network Gateway resource."
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default = {}
}
