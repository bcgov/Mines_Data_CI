# ─────────────────────────────────────────────────────────────────────────────
# Microsoft Purview account
#
# Creates the Purview (Data Map / Unified Catalog) account, grants the listed
# principals Root Collection Admin, and — when enabled — registers the Fabric
# tenant as a data source and configures a recurring scan against it.
#
# Control plane (account, identity, RBAC) is managed by azurerm/azapi.
# Data plane (data source, scan, trigger) has no Terraform provider, so it is
# driven through the scanning REST API from a local-exec script, following the
# same pattern as modules/azure/fabric_connection.
#
# State contains: account attributes and the scan configuration hash.
# State does NOT contain: SP credentials or bearer tokens.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

data "azurerm_client_config" "current" {}

locals {
  name = substr(
    replace(
      var.purview_account_name != null ? var.purview_account_name : "${var.prefix}-${var.project}-${var.suffix}${var.instance_number}-${var.env}",
      " ",
      ""
    ),
    0,
    63
  )

  managed_resource_group_name = var.managed_resource_group_name != null ? var.managed_resource_group_name : "${local.name}-managed"

  # Data-plane endpoint. The root collection always carries the same reference
  # name as the account itself.
  scan_endpoint   = "https://${local.name}.purview.azure.com"
  collection_name = var.collection_name != null ? var.collection_name : local.name

  # Data source / scan names must match ^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$ (3-63).
  fabric_datasource_name = var.fabric_datasource_name != null ? var.fabric_datasource_name : "${local.name}-fabric"
  fabric_scan_name       = var.fabric_scan_name != null ? var.fabric_scan_name : "${local.name}-fabric-scan"

  fabric_tenant_id = var.fabric_tenant_id != null ? var.fabric_tenant_id : data.azurerm_client_config.current.tenant_id

  # Scoped scan: restrict the scan to specific Fabric workspaces. Empty means
  # the whole tenant is scanned.
  workspace_uri_prefixes = [
    for id in var.scan_workspace_ids : "https://app.powerbi.com/groups/${id}"
  ]

  # Everything the data-plane script needs, in one object so a change to any
  # field re-runs the configuration.
  scan_config = {
    endpoint                    = local.scan_endpoint
    collection_name             = local.collection_name
    datasource_name             = local.fabric_datasource_name
    scan_name                   = local.fabric_scan_name
    tenant_id                   = local.fabric_tenant_id
    api_version                 = var.scan_api_version
    include_personal_workspaces = var.include_personal_workspaces
    include_uri_prefixes        = local.workspace_uri_prefixes
    scan_level                  = var.scan_level
    recurrence                  = var.scan_recurrence
    run_on_apply                = var.run_scan_on_apply
  }
}

###############################################################################
# Purview account
###############################################################################

resource "azurerm_purview_account" "this" {
  name                        = local.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  managed_resource_group_name = local.managed_resource_group_name
  public_network_enabled      = var.public_network_enabled
  managed_event_hub_enabled   = var.managed_event_hub_enabled

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# The data plane (collections, data sources, scans) is not immediately
# reachable after the ARM resource reports success. Without this pause the
# first addRootCollectionAdmin call intermittently returns 404.
resource "time_sleep" "wait_for_data_plane" {
  create_duration = var.data_plane_propagation_delay

  depends_on = [azurerm_purview_account.this]
}

###############################################################################
# Access control — Root Collection Admin
#
# Root Collection Admin is the data-plane admin role for the account: it
# carries Collection Admin, Data Source Admin and Data Curator on the root
# collection, and therefore on every collection beneath it.
#
# There is no azurerm resource for this, so the account's addRootCollectionAdmin
# action is invoked directly. The action is idempotent — re-adding an existing
# admin is a no-op.
###############################################################################

resource "azapi_resource_action" "root_collection_admin" {
  for_each = toset(var.admins)

  type        = "Microsoft.Purview/accounts@2021-12-01"
  resource_id = azurerm_purview_account.this.id
  action      = "addRootCollectionAdmin"
  method      = "POST"

  body = {
    objectId = each.value
  }

  depends_on = [time_sleep.wait_for_data_plane]
}

###############################################################################
# Access control — ARM RBAC on the account resource
#
# Optional, and off by default: the deploying service principal usually lacks
# Microsoft.Authorization/roleAssignments/write in the landing zone. This only
# governs management of the Azure resource; catalog access comes from the root
# collection admin assignments above.
###############################################################################

resource "azurerm_role_assignment" "admins" {
  for_each = var.enable_rbac_assignments ? toset(var.admins) : toset([])

  scope                = azurerm_purview_account.this.id
  role_definition_name = var.admin_role_definition_name
  principal_id         = each.value
}

###############################################################################
# Fabric tenant registration + scan
#
# Registers the Fabric tenant as a data source ("Fabric" in the portal, kind
# PowerBI on the wire — the two share one connector) and creates a managed
# identity scan with a recurring trigger.
#
# Prerequisites that cannot be expressed in Terraform — see README:
#   1. The Purview MSI (purview_identity_principal_id output) must belong to an
#      Entra security group.
#   2. That group must be allowed under Fabric admin portal → Tenant settings →
#      Admin API settings → "Allow service principals to use read-only admin
#      APIs", with detailed metadata responses enabled.
###############################################################################

resource "null_resource" "fabric_scan" {
  count = var.enable_fabric_scan ? 1 : 0

  triggers = {
    endpoint        = local.scan_endpoint
    datasource_name = local.fabric_datasource_name
    scan_name       = local.fabric_scan_name
    api_version     = var.scan_api_version
    config_hash     = sha256(jsonencode(local.scan_config))
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/configure_fabric_scan.sh"

    environment = {
      ACTION      = "apply"
      SCAN_CONFIG = jsonencode(local.scan_config)
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/configure_fabric_scan.sh"

    environment = {
      ACTION = "destroy"
      SCAN_CONFIG = jsonencode({
        endpoint        = self.triggers.endpoint
        datasource_name = self.triggers.datasource_name
        scan_name       = self.triggers.scan_name
        api_version     = self.triggers.api_version
      })
    }
  }

  depends_on = [
    azapi_resource_action.root_collection_admin,
    time_sleep.wait_for_data_plane,
  ]
}
