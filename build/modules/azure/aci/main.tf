data "azurerm_client_config" "current" {}

locals {
  name = substr(
    replace(
      var.aci_name == null ? "${var.prefix}-${var.project}-${var.suffix}${var.instance_number}" : var.aci_name,
      " ", ""
    ),
    0, 63
  )

  # use_vnet and use_identity are derived purely from input variables so they
  # are known at plan time and safe to use in count / for_each.
  # var.subnet_id coming from another module output would be unknown at plan
  # time — callers must set var.vnet_mode = true explicitly when passing a
  # computed subnet_id so Terraform can resolve count before apply.
  use_vnet     = var.vnet_mode
  use_identity = !var.vnet_mode && var.create_managed_identity
}

###############################################################################
# User Assigned Managed Identity
# Only created when NOT deploying into a VNet — Azure does not support
# managed identity on VNet-injected container groups.
###############################################################################

resource "azurerm_user_assigned_identity" "aci" {
  count = local.use_identity ? 1 : 0

  name                = "${local.name}-id"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

locals {
  identity_id  = local.use_identity ? azurerm_user_assigned_identity.aci[0].id : var.user_assigned_identity_id
  principal_id = local.use_identity ? azurerm_user_assigned_identity.aci[0].principal_id : var.managed_identity_principal_id
}

###############################################################################
# RBAC — AcrPull (only when identity is in use)
###############################################################################

resource "azurerm_role_assignment" "acr_pull" {
  # Key is static ("acr"), condition uses only known-at-plan booleans.
  # var.acr_id (computed) is safely placed in `scope` (a value, not a key).
  for_each = var.enable_rbac_assignments && local.use_identity ? { "acr" = var.acr_id } : {}

  scope                = each.value
  role_definition_name = "AcrPull"
  principal_id         = local.principal_id

  depends_on = [azurerm_user_assigned_identity.aci]
}

###############################################################################
# RBAC — Key Vault Secrets User (only when identity is in use)
###############################################################################

resource "azurerm_role_assignment" "kv_secrets_user" {
  # Same pattern — static key "kv", computed ID in scope value.
  for_each = var.enable_rbac_assignments && local.use_identity ? { "kv" = var.key_vault_id } : {}

  scope                = each.value
  role_definition_name = "Key Vault Secrets User"
  principal_id         = local.principal_id

  depends_on = [azurerm_user_assigned_identity.aci]
}

###############################################################################
# RBAC — additional role assignments
###############################################################################

resource "azurerm_role_assignment" "additional" {
  for_each = { for policy in var.additional_access_policies : "${policy.object_id}-${policy.role_definition_name}-${policy.scope}" => policy }

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.object_id
  depends_on           = [azurerm_user_assigned_identity.aci]
}

###############################################################################
# Container Group (Jumpbox)
###############################################################################

resource "azurerm_container_group" "aci" {
  name                = local.name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = var.os_type
  restart_policy      = var.restart_policy

  # When subnet_ids is set, ip_address_type must be "Private".
  # When no subnet is used, default to "None" (no public IP for a jumpbox).
  ip_address_type = local.use_vnet ? "Private" : "None"
  subnet_ids      = local.use_vnet ? [var.subnet_id] : null

  # Azure requires ipAddress.ports to be non-empty when ip_address_type = "Private".
  # exposed_port must match a port declared on the container — we use 443/TCP.
  # The NSG DenyAllInbound rule blocks any actual inbound traffic.
  dynamic "exposed_port" {
    for_each = local.use_vnet ? [1] : []
    content {
      port     = 443
      protocol = "TCP"
    }
  }

  # Identity block is omitted entirely when deploying into a VNet —
  # Azure does not support managed identity on VNet-injected container groups.
  dynamic "identity" {
    for_each = local.use_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [local.identity_id]
    }
  }

  # ACR image pull credentials via managed identity (non-VNet only)
  dynamic "image_registry_credential" {
    for_each = var.acr_login_server != null && local.use_identity ? [1] : []
    content {
      server                    = var.acr_login_server
      user_assigned_identity_id = local.identity_id
    }
  }

  # ACR image pull credentials via username/password (VNet mode — no MSI)
  dynamic "image_registry_credential" {
    for_each = var.acr_login_server != null && local.use_vnet && var.acr_username != null ? [1] : []
    content {
      server   = var.acr_login_server
      username = var.acr_username
      password = var.acr_password
    }
  }

  ###############################################################################
  # Jumpbox container
  ###############################################################################

  container {
    name     = var.container_name
    image    = var.container_image
    cpu      = var.cpu
    memory   = var.memory
    commands = var.container_command

    environment_variables        = var.environment_variables
    secure_environment_variables = var.secure_environment_variables

    # When vnet_mode = true, Azure requires at least one port on the container
    # to match the exposed_port block declared at the group level.
    dynamic "ports" {
      for_each = local.use_vnet ? [{ port = 443, protocol = "TCP" }] : var.container_ports
      content {
        port     = ports.value.port
        protocol = ports.value.protocol
      }
    }

    dynamic "volume" {
      for_each = var.volumes
      content {
        name                 = volume.value.name
        mount_path           = volume.value.mount_path
        read_only            = lookup(volume.value, "read_only", false)
        share_name           = lookup(volume.value, "share_name", null)
        storage_account_name = lookup(volume.value, "storage_account_name", null)
        storage_account_key  = lookup(volume.value, "storage_account_key", null)
      }
    }

    dynamic "liveness_probe" {
      for_each = length(var.liveness_probe_exec) > 0 ? [1] : []
      content {
        exec = var.liveness_probe_exec   # list of strings, e.g. ["/bin/sh", "-c", "exit 0"]
        initial_delay_seconds = var.liveness_probe_initial_delay
        period_seconds        = var.liveness_probe_period
      }
    }
  }

  tags = var.tags
}
