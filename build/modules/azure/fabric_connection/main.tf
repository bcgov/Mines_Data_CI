# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection Module — PostgreSQL, Oracle, or Warehouse
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.8"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

locals {
  connector_map = {
    PostgreSQL = {
      type            = "PostgreSQL"
      creation_method = "PostgreSQL.Database"
      server_param    = "server"
      database_param  = "database"
    }

    Oracle = {
      type            = "Oracle"
      creation_method = "Oracle.Database"
      server_param    = "server"
      database_param  = "database"
    }

    Warehouse = {
      type            = "Warehouse"
      creation_method = "Fabric.Warehouse"
      server_param    = null
      database_param  = null
    }
  }

  connector = local.connector_map[var.connection_type]

  # Parameters
  parameters = var.connection_type == "Warehouse" ? [
    {
      name  = "workspaceId"
      value = coalesce(var.workspace_id, "")
    },
    {
      name  = "artifactId"
      value = coalesce(var.warehouse_id, "")
    }
  ] : concat(
    [
      {
        name  = local.connector.server_param
        value = coalesce(var.server, "")
      },
      {
        name  = local.connector.database_param
        value = coalesce(var.database, "")
      }
    ],
    var.connection_type == "Oracle" && var.port != null ? [{
      name  = "port"
      value = tostring(var.port)
    }] : []
  )

  # Credential details - cleaned up
  credential_details = var.connection_type == "Warehouse" ? {
    credentialType       = "OAuth2"
    connectionEncryption = var.connection_encryption
    singleSignOnType     = "None"
    skipTestConnection   = var.skip_test_connection
  } : {
    credentialType       = "Basic"
    connectionEncryption = var.connection_encryption
    singleSignOnType     = "None"
    skipTestConnection   = var.skip_test_connection
    basicCredentials = {
      username = var.username
      passwordReference = {
        keyVaultId = var.password_keyvault_id
        secretName = var.password_secret_name
      }
    }
  }
}

resource "azapi_resource" "this" {
  type      = "Microsoft.Fabric/connections@2024-02-01-preview"
  name      = var.display_name
  parent_id = "/providers/Microsoft.Fabric"   # Important: Tenant level

  body = jsonencode({
    properties = {
      displayName       = var.display_name
      connectivityType  = var.connectivity_type
      privacyLevel      = var.privacy_level
      connectionDetails = {
        type           = local.connector.type
        creationMethod = local.connector.creation_method
        parameters     = local.parameters
      }
      credentialDetails = local.credential_details
    }
  })

  ignore_missing_property = true
  response_export_values  = ["id", "properties"]
}