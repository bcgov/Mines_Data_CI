terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.0.1"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}


###############################################################################
# subnet_allocator — dynamically carves subnets from an existing VNet
#
# For each entry in var.subnets this module:
#   1. Reads the VNet's current subnets via data source
#   2. Calls next_free_subnet.py to find the first non-overlapping CIDR
#   3. Creates the azurerm_subnet with optional service delegation / endpoints
#   4. Creates a dedicated NSG for every subnet with default deny rules
#      plus any per-subnet custom rules supplied by the caller
#   5. Associates each NSG to its subnet
###############################################################################

data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name
}

###############################################################################
# Look up each existing subnet individually to get its address_prefix.
# azurerm_virtual_network.subnets is a set of name strings only — it does not
# expose address_prefix. We must call data "azurerm_subnet" per subnet name.
###############################################################################

data "azurerm_subnet" "existing" {
  for_each = toset(data.azurerm_virtual_network.vnet.subnets)

  name                 = each.key
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = var.vnet_resource_group_name
}

locals {
  # Flatten all existing subnet CIDRs into a single comma-separated string
  # that the Python script can parse. Each subnet may have multiple prefixes;
  # we take the first (primary) one per subnet.
  existing_cidrs = join(",", [
    for s in data.azurerm_subnet.existing : s.address_prefixes[0]
  ])
}

###############################################################################
# CIDR allocation — calls next_free_subnet.py from the module root
###############################################################################

data "external" "cidr" {
  for_each = { for s in var.subnets : s.name => s }

  program = ["python3", "${path.module}/next_free_subnet.py"]

  query = {
    vnet_cidr        = data.azurerm_virtual_network.vnet.address_space[0]
    used_cidrs       = local.existing_cidrs
    prefix_length    = tostring(each.value.prefix_length)
    offset_index     = tostring(index(var.subnets[*].name, each.key))
    sibling_prefixes = join(",", [
      for s in var.subnets : tostring(s.prefix_length)
      if index(var.subnets[*].name, s.name) < index(var.subnets[*].name, each.key)
    ])
  }
}

###############################################################################
# NSG — one per subnet
###############################################################################

resource "azurerm_network_security_group" "this" {
  for_each = { for s in var.subnets : s.name => s }

  name                = "${each.value.name}-nsg"
  resource_group_name = var.nsg_resource_group_name != null ? var.nsg_resource_group_name : var.vnet_resource_group_name
  location            = var.location

  ###########################################################################
  # Default inbound rules
  ###########################################################################

  # Allow inbound from within the same VNet (override with custom rules as needed)
  security_rule {
    name                       = "AllowVnetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow Azure Load Balancer probes
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Deny everything else inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  ###########################################################################
  # Default outbound rules
  ###########################################################################

  # Allow outbound to VNet (private endpoint resolution, inter-subnet)
  security_rule {
    name                       = "AllowVnetOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Allow outbound to Azure services over the backbone (HTTPS only)
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }

  # Deny everything else outbound
  security_rule {
    name                       = "DenyAllOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

###############################################################################
# Per-subnet custom NSG rules (additive on top of the defaults above)
###############################################################################

resource "azurerm_network_security_rule" "custom" {
  for_each = {
    for item in flatten([
      for s in var.subnets : [
        for rule in coalesce(s.nsg_rules, []) : {
          key    = "${s.name}-${rule.name}"
          subnet = s.name
          rule   = rule
        }
      ]
    ]) : item.key => item
  }

  name                        = each.value.rule.name
  priority                    = each.value.rule.priority
  direction                   = each.value.rule.direction
  access                      = each.value.rule.access
  protocol                    = each.value.rule.protocol
  source_port_range           = lookup(each.value.rule, "source_port_range", "*")
  destination_port_range      = lookup(each.value.rule, "destination_port_range", "*")
  source_address_prefix       = lookup(each.value.rule, "source_address_prefix", "*")
  destination_address_prefix  = lookup(each.value.rule, "destination_address_prefix", "*")
  resource_group_name         = var.nsg_resource_group_name != null ? var.nsg_resource_group_name : var.vnet_resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet].name

  depends_on = [azurerm_network_security_group.this]
}
###############################################################################
# Subnets — created via azapi_resource so the NSG is attached in a single
# atomic PUT call. azurerm_subnet + azurerm_subnet_network_security_group_association
# uses two separate API calls which fails the Landing Zone policy:
# "Subnets must have a Network Security Group."
###############################################################################

resource "azapi_resource" "subnet" {
  for_each = { for s in var.subnets : s.name => s }

  type      = "Microsoft.Network/virtualNetworks/subnets@2024-03-01"
  name      = each.value.name
  parent_id = data.azurerm_virtual_network.vnet.id

  body = {
    properties = {
      addressPrefixes  = [data.external.cidr[each.key].result["cidr"]]
      serviceEndpoints = [
        for ep in coalesce(each.value.service_endpoints, []) : { service = ep }
      ]

      # NSG attached inline — satisfies the policy in a single API call
      networkSecurityGroup = {
        id = azurerm_network_security_group.this[each.key].id
      }

      delegations = each.value.delegation != null ? [
        {
          name = each.value.delegation.name
          properties = {
            serviceName = each.value.delegation.service_name
          }
        }
      ] : []
    }
  }

  # Ensure NSG (and any custom rules) exist before the subnet is created
  depends_on = [
    azurerm_network_security_group.this,
    azurerm_network_security_rule.custom,
  ]

  # Ignore drifts Azure introduces automatically after creation
  # (e.g. privateEndpointNetworkPolicies, provisioningState fields)
  lifecycle {
    ignore_changes = [body]
  }
}
