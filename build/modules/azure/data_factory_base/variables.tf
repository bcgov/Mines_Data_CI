# modules/data_factory/variables.tf

# resource naming variables #

variable "key_vault_name" {
  type        = string
  description = "Name of the existing key vault"
  default     = null
}

variable "Instance_Number" {
  type        = string
  description = "Instance number for resource naming"
  default     = "00"
}

variable "project" {
  type        = string
  description = "Project name"
  default     = "dp"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "azure"
}

variable "prefix" {
  type        = string
  description = "Resource name prefix"
  default     = "cdd"
}

variable "suffix" {
  type        = string
  description = "Resource name suffix"
  default     = "adf"
}

# Resource-Specific Name Overrides (Optional)
variable "datafactory_name" {
  description = "Custom name for Data Factory (if null, will be auto-generated)"
  type        = string
  default     = null
}

variable "ir_name" {
  description = "Custom name for Integration Runtime (if null, will be auto-generated)"
  type        = string
  default     = null
}

variable "shir_name" {
  description = "Custom name for Self-Hosted Integration Runtime (if null, will be auto-generated)"
  type        = string
  default     = null
}

variable "mpe_name" {
  description = "Custom name for Managed Private Endpoint (if null, will be auto-generated)"
  type        = string
  default     = null
}

variable "linked_service_kv_name" {
  description = "Custom name for Key Vault Linked Service (if null, will be auto-generated)"
  type        = string
  default     = null
}

# end of naming variables #


# association variables #

variable "resource_group_name" {
  description = "The name of the existing resource group"
  type        = string
  default     = null
}

# end association variables #


# configuration variables #

variable "location" {
  description = "The location where resources should be created"
  type        = string
  default     = "eastus2"
}

variable "name" {
  description = "Specifies the name of the Data Factory. Must be globally unique."
  type        = string
  default     = null
}

variable "public_network_enabled" {
  description = "Is the Data Factory visible to the public network?"
  type        = bool
  default     = true
}

variable "virtual_network_enabled" {
  type        = bool
  description = "Managed Virtual Network for Integration runtime"
  default     = true
}

variable "managed_virtual_network_enabled" {
  description = "Is Managed Virtual Network enabled?"
  type        = bool
  default     = true
}

variable "time_to_live_min" {
  type        = string
  description = "TTL for Integration runtime"
  default     = 15
}

variable "cleanup_enabled" {
  type        = bool
  description = "Cluster will not be recycled and it will be used in next data flow activity run until TTL (time to live) is reached if this is set as false"
  default     = true
}

variable "compute_type" {
  type        = string
  description = "Compute type of the cluster which will execute data flow job: [General|ComputeOptimized|MemoryOptimized]"
  default     = "General"
}

variable "core_count" {
  type        = number
  description = "Core count of the cluster which will execute data flow job: [8|16|32|48|144|272]"
  default     = 8
}

variable "permissions" {
  type        = list(map(string))
  description = "Data Factory permission map"
  default = [
    {
      object_id = null
      role      = null
    }
  ]
}

variable "vsts_enabled" {
  description = "Enable or disable the VSTS configuration."
  type        = bool
  default     = false
}

variable "vsts_configuration" {
  description = "A vsts_configuration block as defined."
  type = object({
    account_name       = string
    branch_name        = string
    project_name       = string
    repository_name    = string
    root_folder        = string
    tenant_id          = string
    publishing_enabled = bool
  })

  default = {
    account_name       = "DataIntelligencePlatform"
    branch_name        = "adf_publish"
    project_name       = "FalconDeployment"
    repository_name    = "ADF_Deployment"
    root_folder        = "/code"
    tenant_id          = ""
    publishing_enabled = true
  }
}

variable "global_parameters" {
  description = "A list of global parameters for Azure Data Factory."
  type = list(object({
    name  = string
    type  = string # Possible Values: Array, Bool, Float, Int, Object, String
    value = any    # Using `any` to accommodate various types of values
  }))
  default = [
    {
      name  = "keyvault_name"
      type  = "String"
      value = "example-keyvault"
    },
    {
      name  = "notifications_enabled"
      type  = "Bool"
      value = true
    },
    {
      name  = "notification_endpoint"
      type  = "String"
      value = "https://example.com/notify"
    },
    {
      name  = "triggers_enabled"
      type  = "Bool"
      value = true
    }
  ]
}

# notification variables #

variable "action_group_name" {
  description = "The action group for failure notifications"
  type        = string
  default     = "adffailalert"
}

variable "email_address" {
  description = "Email that will receive alert"
  type        = string
  default     = "climate_emission_alert@lululemon.com"
}

variable "enable_action_group_notification" {
  description = "If action group notifications should be enabled"
  type        = bool
  default     = false
}

# variable "pep_storage_account_id" {
#   description = "Private end point storage account id"
#   type        = string
#   default     = ""
# }

# tagging variables #

variable "tags" {
  description = "Tags to apply to the Azure resources"
  type        = map(string)
  default = {
    "business_application-name"     = "data-platform"
    "business_department"           = "mines"
    "business_project-name"         = "fabric"
    "business_cost-center"          = ""
    "deployment_automation"         = ""
    "deployment_automation_version" = "v1.0"
    "application_environment"       = "Dev"
    "security_compliance"           = ""
  }
}

# end tagging variables #