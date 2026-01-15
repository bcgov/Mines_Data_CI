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

variable "fabric_domain_parent" {
  description = "Override name for the fabric domain parent. If provided, it will be used instead of the generated name."
  type        = string
  default     = null
}

variable "fabric_domain_child" {
  description = "Override name for the fabric domain child. If provided, it will be used instead of the generated name."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the Fabric Domain."
  type        = string
  default     = ""
}

variable "contributors_scope" {
  description = "The Domain contributors scope."
  type        = string
  default     = "AdminsOnly" # Default value (optional)

  validation {
    condition     = contains(["AdminsOnly", "AllTenant", "SpecificUsersAndGroups"], var.contributors_scope)
    error_message = "The contributors_scope must be one of the following: AdminsOnly, AllTenant, SpecificUsersAndGroups."
  }
}

# New Variable to Enable/Disable Child Domains
variable "enable_child_domain" {
  description = "Flag to enable the creation of child domains."
  type        = bool
  default     = false
}

# New Variable to Specify Subdomains
variable "child_subdomains" {
  description = "List of subdomains to create under the parent domain. Required if enable_child_domain is true."
  type        = list(string)
  default     = []

  validation {
    condition     = !(var.enable_child_domain) || (var.enable_child_domain && length(var.child_subdomains) > 0)
    error_message = "When enable_child_domain is true, child_subdomains must be a non-empty list."
  }
}
