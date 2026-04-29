# modules/data_factory_base/main.tf
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "existing" {
  name                = var.key_vault_name
  resource_group_name = var.resource_group_name
}

locals {
  datafactory_name  = substr(replace(var.datafactory_name == null ? "${var.prefix}-${var.project}-adf${var.Instance_Number}" : var.datafactory_name, " ", ""), 0, 30)
  ir_name           = substr(replace(var.ir_name == null ? "${var.prefix}-${var.project}-ir${var.Instance_Number}" : var.ir_name, " ", ""), 0, 30)
  shir_name         = substr(replace(var.shir_name == null ? "${var.prefix}-${var.project}-shir${var.Instance_Number}" : var.shir_name, " ", ""), 0, 30)
  mpe_name          = substr(replace(var.mpe_name == null ? "${var.prefix}-${var.project}-mpe${var.Instance_Number}" : var.mpe_name, " ", ""), 0, 30)
  linked_service_kv = substr(replace(var.linked_service_kv_name == null ? "${var.project}-kv${var.Instance_Number}" : var.linked_service_kv_name, " ", ""), 0, 30)
  location          = var.location == null ? "eastus2" : var.location
}

resource "azurerm_data_factory" "adf" {
  name                            = local.datafactory_name
  location                        = local.location
  resource_group_name             = data.azurerm_resource_group.existing.name
  public_network_enabled          = var.public_network_enabled
  managed_virtual_network_enabled = var.managed_virtual_network_enabled

  dynamic "vsts_configuration" {
    for_each = var.vsts_enabled ? [1] : []

    content {
      account_name    = var.vsts_configuration.account_name
      branch_name     = var.vsts_configuration.branch_name
      project_name    = var.vsts_configuration.project_name
      repository_name = var.vsts_configuration.repository_name
      root_folder     = var.vsts_configuration.root_folder
      tenant_id       = var.vsts_configuration.tenant_id
    }
  }
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags

  dynamic "global_parameter" {
    for_each = { for param in var.global_parameters : param.name => param }

    content {
      name  = global_parameter.value.name
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }
}

# Add access policy for Data Factory to existing Key Vault
resource "azurerm_key_vault_access_policy" "adf_policy" {
  key_vault_id = data.azurerm_key_vault.existing.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.adf.identity[0].principal_id

  certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]
  key_permissions         = ["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"]
  secret_permissions      = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
}

resource "azurerm_data_factory_integration_runtime_azure" "ir" {
  data_factory_id         = azurerm_data_factory.adf.id
  location                = "AutoResolve"
  name                    = local.ir_name
  time_to_live_min        = var.time_to_live_min
  virtual_network_enabled = var.virtual_network_enabled
  cleanup_enabled         = var.cleanup_enabled
  compute_type            = var.compute_type
  core_count              = var.core_count
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  count           = 1
  name            = local.shir_name
  data_factory_id = azurerm_data_factory.adf.id
}

resource "azurerm_data_factory_linked_service_key_vault" "adflskv" {
  name            = local.linked_service_kv
  data_factory_id = azurerm_data_factory.adf.id
  key_vault_id    = data.azurerm_key_vault.existing.id
}

# Monitoring and alerts
resource "azurerm_monitor_action_group" "mag" {
  name                = var.action_group_name
  resource_group_name = data.azurerm_resource_group.existing.name
  short_name          = "failalert"

  email_receiver {
    name                    = "sendtoemail"
    email_address           = var.email_address
    use_common_alert_schema = true
  }
  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "mmahcu" {
  name                = "high-cpu-utilization-alert"
  resource_group_name = data.azurerm_resource_group.existing.name
  scopes              = [azurerm_data_factory.adf.id]
  description         = "Trigger an alert when CPU utilization is over 95% every 1 hour"

  criteria {
    metric_namespace = "Microsoft.DataFactory/factories"
    metric_name      = "IntegrationRuntimeCpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95

    dimension {
      name     = "IntegrationRuntimeName"
      operator = "Include"
      values   = [azurerm_data_factory_integration_runtime_azure.ir.name]
    }

  }

  action {
    action_group_id = azurerm_monitor_action_group.mag.id
  }
  tags        = var.tags
  frequency   = "PT1H"
  severity    = 2
  window_size = "PT1H"
  enabled     = var.enable_action_group_notification
  depends_on  = [azurerm_data_factory.adf]
}

resource "azurerm_monitor_metric_alert" "mmamhcu" {
  name                = "mv-high-cpu-utilization-alert"
  resource_group_name = data.azurerm_resource_group.existing.name
  scopes              = [azurerm_data_factory.adf.id]
  description         = "Trigger an alert when CPU utilization is over 95% every 1 hour"

  criteria {
    metric_namespace = "Microsoft.DataFactory/factories"
    metric_name      = "MVNetIRCopyCapacityUtilization"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 95

    dimension {
      name     = "IntegrationRuntimeName"
      operator = "Include"
      values   = [azurerm_data_factory_integration_runtime_azure.ir.name]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.mag.id
  }
  tags        = var.tags
  frequency   = "PT1H"
  severity    = 2
  window_size = "PT1H"
  enabled     = var.enable_action_group_notification
  depends_on  = [azurerm_data_factory.adf]
}

# resource "azurerm_data_factory_managed_private_endpoint" "mpe" {
#   name               = local.mpe_name
#   data_factory_id    = azurerm_data_factory.adf.id
#   target_resource_id = var.pep_storage_account_id
#   subresource_name   = "dfs"
# }