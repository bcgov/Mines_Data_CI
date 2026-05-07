data "azurerm_client_config" "current" {}

locals {
  name = substr(
    replace(
      var.acr_name == null ? "${var.prefix}-${var.project}-${var.suffix}${var.instance_number}" : var.acr_name,
      "-", ""  # ACR names cannot contain hyphens
    ),
    0, 50
  )

  private_endpoint_name           = var.private_endpoint_name != null ? var.private_endpoint_name : "${local.name}-pe"
  private_service_connection_name = var.private_service_connection_name != null ? var.private_service_connection_name : "${local.name}-psc"
}

###############################################################################
# Azure Container Registry
###############################################################################

resource "azurerm_container_registry" "acr" {
  name                          = local.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  zone_redundancy_enabled       = var.zone_redundancy_enabled
  data_endpoint_enabled         = var.data_endpoint_enabled

  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  dynamic "network_rule_set" {
    for_each = length(var.ip_rules) > 0 ? [1] : []
    content {
      default_action = "Deny"

      dynamic "ip_rule" {
        for_each = var.ip_rules
        content {
          action   = "Allow"
          ip_range = ip_rule.value
        }
      }
    }
  }

  tags = var.tags
}

###############################################################################
# RBAC — deploying identity / managed identity
###############################################################################

resource "azurerm_role_assignment" "app" {
  for_each = var.enable_rbac_assignments ? { "app" = var.managed_identity_delegate != null ? var.managed_identity_delegate : data.azurerm_client_config.current.object_id } : {}

  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}

###############################################################################
# RBAC — additional users / groups / service principals
###############################################################################

resource "azurerm_role_assignment" "additional" {
  for_each = { for policy in var.additional_access_policies : "${policy.object_id}-${policy.role_definition_name}" => policy }

  scope                = azurerm_container_registry.acr.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.object_id
  depends_on           = [azurerm_role_assignment.app]
}

###############################################################################
# Private Endpoint
###############################################################################

resource "azurerm_private_endpoint" "acr" {
  for_each = var.private_endpoint_enabled ? { "acr" = var.private_endpoint_subnet_id } : {}

  name                = local.private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = each.value

  private_service_connection {
    name                           = local.private_service_connection_name
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = length(var.private_dns_zone_ids) > 0 ? [1] : []
    content {
      name                 = "${local.name}-dns-zone-group"
      private_dns_zone_ids = var.private_dns_zone_ids
    }
  }

  tags = var.tags
}
