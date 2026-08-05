# modules/azure/purview/variables.tf

###############################################################################
# Naming
###############################################################################

variable "prefix" {
  type        = string
  description = "Resource name prefix."
}

variable "project" {
  type        = string
  description = "Project name."
  default     = "mdp"
}

variable "suffix" {
  type        = string
  description = "Resource type abbreviation used in the account name."
  default     = "pv"
}

variable "instance_number" {
  type        = string
  description = "Zero-padded instance number."
  default     = "01"
}

variable "env" {
  type        = string
  description = "Environment name (dev, test, prod)."
  default     = "dev"
}

variable "purview_account_name" {
  description = "Name of the Purview account. When create_account is false this identifies the existing account — leave null to discover the single account in the subscription. When create_account is true it overrides the generated name."
  type        = string
  default     = null
}

###############################################################################
# Purview account
###############################################################################

variable "create_account" {
  description = "Whether to create the Purview account. A Microsoft Entra tenant may hold only one account, so this defaults to false and the module attaches to the existing account instead. Creating a second returns 409 / error 35001."
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Resource group holding the Purview account. Required when create_account is true; otherwise optional, and used only to narrow the search for the existing account."
  type        = string
  default     = null

  validation {
    condition     = !var.create_account || var.resource_group_name != null
    error_message = "resource_group_name is required when create_account is true."
  }
}

variable "location" {
  description = "Azure region for the Purview account."
  type        = string
  default     = "canadacentral"
}

variable "managed_resource_group_name" {
  description = "Name of the resource group Purview creates for its managed resources. Must not already exist. Defaults to <account name>-managed."
  type        = string
  default     = null
}

variable "public_network_enabled" {
  description = "Whether the Purview account is reachable over the public network. Scanning Fabric with the Azure integration runtime requires public access; set to false only when using a managed VNet runtime."
  type        = bool
  default     = true
}

variable "managed_event_hub_enabled" {
  description = "Whether Purview provisions its managed Event Hub namespace (used by the Atlas Kafka endpoints)."
  type        = bool
  default     = false
}

variable "data_plane_propagation_delay" {
  description = "How long to wait after account creation before calling the data plane. The catalog is not immediately reachable once ARM reports success."
  type        = string
  default     = "60s"
}

###############################################################################
# Access control
###############################################################################

variable "admins" {
  description = "Entra object IDs granted Root Collection Admin on the Purview account — the data-plane admin role covering every collection, data source and scan."
  type        = list(string)
  default     = []
}

variable "include_deploying_principal_as_admin" {
  description = "Whether to add the deploying service principal to the Root Collection Admins. Required on an account this module did not create — without it the principal cannot call the scanning data plane. Harmless when creating, since the creator gets the role automatically."
  type        = bool
  default     = true
}

variable "account_api_version" {
  description = "API version for the Purview control plane (used by the addRootCollectionAdmin action)."
  type        = string
  default     = "2021-12-01"
}

variable "admin_retry_attempts" {
  description = "Attempts per admin grant. Each grant rewrites the root collection policy under optimistic concurrency, so a retry is needed when calls collide or when a newly created account is still initialising."
  type        = number
  default     = 6
}

variable "admin_retry_delay_seconds" {
  description = "Seconds before the first retry of a failed admin grant. Doubles on each subsequent attempt."
  type        = number
  default     = 10
}

variable "admin_settle_seconds" {
  description = "Seconds to wait between consecutive admin grants, so each call reads the policy the previous write left behind."
  type        = number
  default     = 5
}

variable "enable_rbac_assignments" {
  description = "Whether to also create ARM role assignments on the account resource for the admins. Disable if the service principal lacks Microsoft.Authorization/roleAssignments/write."
  type        = bool
  default     = false
}

variable "admin_role_definition_name" {
  description = "Built-in Azure role granted to the admins on the account resource when enable_rbac_assignments is true."
  type        = string
  default     = "Contributor"
}

###############################################################################
# Fabric tenant registration and scan
###############################################################################

variable "enable_fabric_scan" {
  description = "Whether to register the Fabric tenant as a data source and configure a scan."
  type        = bool
  default     = true
}

variable "fabric_tenant_id" {
  description = "Entra tenant ID of the Fabric tenant to scan. Defaults to the tenant of the deploying service principal (same-tenant scenario)."
  type        = string
  default     = null
}

variable "fabric_datasource_name" {
  description = "Optional data source name override. Must be 3-63 characters, alphanumeric and single hyphens only."
  type        = string
  default     = null
}

variable "fabric_scan_name" {
  description = "Optional scan name override. Must be 3-63 characters, alphanumeric and single hyphens only."
  type        = string
  default     = null
}

variable "collection_name" {
  description = "Collection the data source and scan are registered under. Defaults to the root collection, which carries the same reference name as the account."
  type        = string
  default     = null
}

variable "scan_workspace_ids" {
  description = "Fabric workspace IDs to scope the scan to. Leave empty to scan the whole tenant."
  type        = list(string)
  default     = []
}

variable "include_personal_workspaces" {
  description = "Whether personal (My workspace) workspaces are included in the scan."
  type        = bool
  default     = false
}

variable "scan_level" {
  description = "Scan level used by the recurring trigger. Accepted values: Full, Incremental."
  type        = string
  default     = "Incremental"

  validation {
    condition     = contains(["Full", "Incremental"], var.scan_level)
    error_message = "scan_level must be one of: Full, Incremental."
  }
}

variable "scan_recurrence" {
  description = "Recurrence for the scan trigger. start_time must be an ISO-8601 UTC timestamp; week_days applies when frequency is Week."
  type = object({
    frequency  = optional(string, "Week")
    interval   = optional(number, 1)
    start_time = optional(string, "2026-01-05T06:00:00Z")
    timezone   = optional(string, "UTC")
    hours      = optional(list(number), [6])
    minutes    = optional(list(number), [0])
    week_days  = optional(list(string), ["Sunday"])
  })
  default = {}

  validation {
    condition     = contains(["Day", "Week", "Month"], var.scan_recurrence.frequency)
    error_message = "scan_recurrence.frequency must be one of: Day, Week, Month."
  }
}

variable "run_scan_on_apply" {
  description = "Whether to kick off a scan run immediately after the scan is configured, rather than waiting for the first scheduled run."
  type        = bool
  default     = false
}

variable "scan_api_version" {
  description = "API version for the Purview scanning data plane."
  type        = string
  default     = "2023-09-01"
}

###############################################################################
# Tagging
###############################################################################

variable "tags" {
  description = "Tags to apply to the Purview account."
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
