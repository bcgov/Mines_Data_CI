# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = ">= 1.5"
      # configuration_aliases = [fabric.auth]
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
}

resource "fabric_connection" "this" {
  # provider = fabric.auth

  display_name      = var.display_name
  connectivity_type = var.connectivity_type
  privacy_level     = var.privacy_level

  gateway_id = var.connectivity_type == "ShareableCloud" ? null : var.gateway_id

  connection_details = {
    type            = local.connector.type
    creation_method = local.connector.creation_method

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
      var.connection_type == "Oracle" && var.port != null ? [
        {
          name  = "port"
          value = tostring(var.port)
        }
      ] : []
    )
  }

  credential_details = var.connection_type == "Warehouse" ? {
    connection_encryption = var.connection_encryption
    credential_type       = "OAuth2"
    single_sign_on_type   = "None"
    skip_test_connection  = var.skip_test_connection

    basic_credentials = null
  } : {
    connection_encryption = var.connection_encryption
    credential_type       = "Basic"
    single_sign_on_type   = "None"
    skip_test_connection  = var.skip_test_connection

    basic_credentials = {
      username = var.username

      password_reference = {
        key_vault_id = var.password_keyvault_id
        secret_name  = var.password_secret_name
      }
    }
  }
}