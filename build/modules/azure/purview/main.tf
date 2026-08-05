# ─────────────────────────────────────────────────────────────────────────────
# Microsoft Purview account
#
# Attaches to the tenant's Purview (Data Map / Unified Catalog) account — or
# creates it when the tenant has none — grants the listed principals Root
# Collection Admin, and, when enabled, registers the Fabric tenant as a data
# source with a recurring scan.
#
# A Microsoft Entra tenant may hold exactly one Purview account, so
# create_account defaults to false and the account is discovered instead.
#
# The account and ARM RBAC are managed by azurerm. Collection admin grants and
# the data plane (data source, scan, trigger) have no Terraform provider, so
# they are driven through the REST APIs from local-exec scripts, following the
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
  # Name of the account this module works against. When create_account is false
  # (the default — see the discovery block below) this is the existing
  # tenant-level account; the naming convention only applies when creating one.
  desired_name = substr(
    replace(
      var.purview_account_name != null ? var.purview_account_name : "${var.prefix}-${var.project}-${var.suffix}${var.instance_number}-${var.env}",
      " ",
      ""
    ),
    0,
    63
  )

  managed_resource_group_name = var.managed_resource_group_name != null ? var.managed_resource_group_name : "${local.desired_name}-managed"

  # Resolved account — either the one this module creates or the one it found.
  # one() returns null rather than erroring when the resource has count = 0.
  created      = one(azurerm_purview_account.this)
  discovered   = var.create_account ? [] : try(data.azurerm_resources.purview[0].resources, [])
  account_id   = local.created != null ? local.created.id : try(local.discovered[0].id, null)
  account_name = local.created != null ? local.created.name : try(local.discovered[0].name, null)

  # Resource group is not returned by azurerm_resources, so it comes out of the
  # resource ID.
  account_rg = local.account_id != null ? try(regex("/resourceGroups/([^/]+)/", local.account_id)[0], null) : null

  account_identity_principal_id = (
    local.created != null
    ? local.created.identity[0].principal_id
    : try(data.azurerm_purview_account.existing[0].identity[0].principal_id, null)
  )

  # Data-plane endpoint. The root collection always carries the same reference
  # name as the account itself.
  scan_endpoint   = local.account_name != null ? "https://${local.account_name}.purview.azure.com" : null
  collection_name = var.collection_name != null ? var.collection_name : local.account_name

  # Data source / scan names must match ^[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*$ (3-63).
  # They are derived from the workspace naming convention, not the account name,
  # so a shared tenant-level account still gets recognisable per-environment
  # entries in the Data Map.
  source_name            = "${var.prefix}-${var.project}-fabric${var.instance_number}-${var.env}"
  fabric_datasource_name = var.fabric_datasource_name != null ? var.fabric_datasource_name : local.source_name
  fabric_scan_name       = var.fabric_scan_name != null ? var.fabric_scan_name : "${local.source_name}-scan"

  fabric_tenant_id = var.fabric_tenant_id != null ? var.fabric_tenant_id : data.azurerm_client_config.current.tenant_id

  # The deploying service principal needs Root Collection Admin to call the
  # scanning data plane. It gets that automatically only when it created the
  # account, so on an existing account it has to be added explicitly.
  admins = toset(compact(concat(
    var.admins,
    var.include_deploying_principal_as_admin ? [data.azurerm_client_config.current.object_id] : []
  )))

  # Sorted so the trigger value is stable across plans regardless of set order.
  sorted_admins = sort(tolist(local.admins))

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

  account_ambiguous_message = <<-EOT
    ${length(local.discovered)} Microsoft Purview accounts were found in
    subscription ${data.azurerm_client_config.current.subscription_id}. Set
    PURVIEW_ACCOUNT_NAME (and optionally PURVIEW_RESOURCE_GROUP_NAME) to say
    which one this configuration should register the Fabric scan against.
  EOT

  account_missing_message = <<-EOT
    No Microsoft Purview account was found in subscription ${data.azurerm_client_config.current.subscription_id}${var.purview_account_name != null ? " named '${var.purview_account_name}'" : ""}${var.resource_group_name != null ? " in resource group '${var.resource_group_name}'" : ""}.

    A tenant may hold only one Purview account, so this module attaches to the
    existing one by default. Find it with:

      az graph query -q "Resources | where type =~ 'microsoft.purview/accounts' | project name, resourceGroup, subscriptionId"

    Then set PURVIEW_ACCOUNT_NAME (and PURVIEW_RESOURCE_GROUP_NAME if it is in
    this subscription). If the account lives in another subscription, the
    deploying service principal needs Reader on it. If the tenant genuinely has
    no account, set PURVIEW_CREATE_ACCOUNT = true.
  EOT
}

###############################################################################
# Purview account
#
# A Microsoft Entra tenant may hold exactly one Purview account. Creating a
# second returns 409 / error 35001, so the default is to attach to the account
# that already exists rather than create one. Set create_account = true only for
# a tenant that has none, or one holding pre-existing quota for more.
###############################################################################

data "azurerm_resources" "purview" {
  count = var.create_account ? 0 : 1

  type                = "Microsoft.Purview/accounts"
  name                = var.purview_account_name
  resource_group_name = var.resource_group_name
}

data "azurerm_purview_account" "existing" {
  count = !var.create_account && local.account_name != null ? 1 : 0

  name                = local.account_name
  resource_group_name = local.account_rg
}

resource "azurerm_purview_account" "this" {
  count = var.create_account ? 1 : 0

  name                        = local.desired_name
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
# first addRootCollectionAdmin call intermittently returns 404. Skipped
# entirely for an account that already exists.
resource "time_sleep" "wait_for_data_plane" {
  count = var.create_account ? 1 : 0

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
# There is no azurerm resource for this, and one azapi_resource_action per
# admin does not work: every call rewrites the root collection's metadata
# policy under optimistic concurrency, so Terraform's parallel execution makes
# the calls collide on the entity tag (400 / 1002, "The entity Etag did not
# match in artifact store"). The grants are therefore made sequentially, with
# retries, by add_root_collection_admins.sh.
#
# Re-adding an existing admin is a no-op, so this is safe to re-run.
###############################################################################

resource "null_resource" "root_collection_admins" {
  count = length(local.admins) > 0 ? 1 : 0

  triggers = {
    account_id  = local.account_id
    admins      = join(",", local.sorted_admins)
    api_version = var.account_api_version
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/add_root_collection_admins.sh"

    environment = {
      ACCOUNT_ID     = local.account_id
      ADMINS         = jsonencode(local.sorted_admins)
      API_VERSION    = var.account_api_version
      MAX_ATTEMPTS   = tostring(var.admin_retry_attempts)
      RETRY_DELAY    = tostring(var.admin_retry_delay_seconds)
      SETTLE_SECONDS = tostring(var.admin_settle_seconds)
    }
  }

  lifecycle {
    precondition {
      condition     = local.account_id != null
      error_message = local.account_missing_message
    }

    precondition {
      condition     = length(local.discovered) < 2
      error_message = local.account_ambiguous_message
    }
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

  scope                = local.account_id
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

  lifecycle {
    precondition {
      condition     = local.account_id != null
      error_message = local.account_missing_message
    }

    precondition {
      condition     = length(local.discovered) < 2
      error_message = local.account_ambiguous_message
    }
  }

  depends_on = [
    null_resource.root_collection_admins,
    time_sleep.wait_for_data_plane,
  ]
}
