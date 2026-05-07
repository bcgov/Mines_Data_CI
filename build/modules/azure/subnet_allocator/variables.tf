# modules/azure/subnet_allocator/variables.tf

variable "vnet_name" {
  description = "Name of the existing Virtual Network to allocate subnets within."
  type        = string
}

variable "vnet_resource_group_name" {
  description = "Resource group that contains the existing Virtual Network."
  type        = string
}

variable "location" {
  description = "Azure region where NSGs will be created. Should match the VNet region."
  type        = string
  default     = "canadacentral"
}

variable "nsg_resource_group_name" {
  description = "Resource group to place NSGs in. Defaults to vnet_resource_group_name if null."
  type        = string
  default     = null
}

variable "subnets" {
  description = <<-EOT
    List of subnets to create. CIDRs are computed automatically — no address_prefix needed.
    Every subnet gets a dedicated NSG with default allow-VNet / deny-all rules automatically.

    Fields:
      name              (required) — subnet resource name
      prefix_length     (required) — desired CIDR prefix, e.g. 24, 26, 27, 28
      service_endpoints (optional) — list of service endpoint strings
      delegation        (optional) — service delegation block:
        name         — delegation label (arbitrary)
        service_name — Azure service, e.g. "Microsoft.ContainerInstance/containerGroups"
        actions      — list of delegated actions
      nsg_rules         (optional) — list of extra NSG rules added on top of the defaults:
        name                       (required) — rule name
        priority                   (required) — 200–4095 (100/110/4096 are reserved by defaults)
        direction                  (required) — Inbound | Outbound
        access                     (required) — Allow | Deny
        protocol                   (required) — Tcp | Udp | Icmp | * 
        source_port_range          (optional) — default "*"
        destination_port_range     (optional) — default "*"
        source_address_prefix      (optional) — default "*"
        destination_address_prefix (optional) — default "*"

    Example:
      subnets = [
        {
          name          = "mines-fabric-aci-snet"
          prefix_length = 27
          delegation = {
            name         = "aci-delegation"
            service_name = "Microsoft.ContainerInstance/containerGroups"
            actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action"]
          }
          nsg_rules = [
            {
              name                       = "AllowHttpsInbound"
              priority                   = 200
              direction                  = "Inbound"
              access                     = "Allow"
              protocol                   = "Tcp"
              destination_port_range     = "443"
              source_address_prefix      = "10.0.0.0/8"
              destination_address_prefix = "*"
            }
          ]
        },
        {
          name              = "mines-fabric-pe-snet"
          prefix_length     = 27
          service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
        }
      ]
  EOT
  type = list(object({
    name              = string
    prefix_length     = number
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = optional(string, "*")
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
}

variable "tags" {
  description = "Tags to apply to all NSGs created by this module."
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
