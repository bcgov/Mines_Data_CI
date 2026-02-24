data "azurerm_client_config" "current" {}

locals {
  name        = substr(replace(var.key_vault_name == null ? "${var.prefix}-${var.project}-${var.suffix}${var.Instance_Number}" : var.key_vault_name, " ", ""), 0, 24)
  delegate_id = var.managed_identity_delegate == null ? data.azurerm_client_config.current.object_id : var.managed_identity_delegate
  private_endpoint_name           = var.private_endpoint_name != null ? var.private_endpoint_name : "${local.name}-pe"
  private_service_connection_name = var.private_service_connection_name != null ? var.private_service_connection_name : "${local.name}-psc"
}

###############################################################################
# Key Vault
###############################################################################

resource "azurerm_key_vault" "kv" {
  name                            = local.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku_name                        = var.sku_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  dynamic "network_acls" {
    for_each = length(var.ip_rules) > 0 || length(var.virtual_network_subnet_ids) > 0 ? [1] : []
    content {
      bypass                     = "AzureServices"
      default_action             = "Deny"
      ip_rules                   = var.ip_rules
      virtual_network_subnet_ids = var.virtual_network_subnet_ids
    }
  }

  tags = var.tags
}

###############################################################################
# Key Vault Access Policy — deploying identity / managed identity
###############################################################################

resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.delegate_id
  certificate_permissions = var.certificate_permissions
  key_permissions         = var.key_permissions
  secret_permissions      = var.secret_permissions
  storage_permissions     = var.storage_permissions
}

###############################################################################
# Key Vault Access Policies — additional users / groups / service principals
###############################################################################

resource "azurerm_key_vault_access_policy" "additional" {
  for_each = { for policy in var.additional_access_policies : policy.object_id => policy }

  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id
  certificate_permissions = each.value.certificate_permissions
  key_permissions         = each.value.key_permissions
  secret_permissions      = each.value.secret_permissions
  storage_permissions     = each.value.storage_permissions
}

###############################################################################
# Private Endpoint
###############################################################################

resource "azurerm_private_endpoint" "kv" {
  for_each = var.private_endpoint_enabled && var.private_endpoint_subnet_id != null ? toset(["kv"]) : toset([])

  name                = local.private_endpoint_name
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = local.private_service_connection_name
    private_connection_resource_id = azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
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