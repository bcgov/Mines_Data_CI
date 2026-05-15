# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL or Oracle
#
# Creates a Fabric ShareableCloud connection that Copy Jobs and Pipelines
# can reference. Credentials are passed as write-only attributes to avoid
# state persistence.
#
# Connection types supported:
#   - PostgreSQL  →  type=PostgreSQL,  creation_method=PostgreSQL.Database
#   - Oracle      →  type=Oracle,      creation_method=Oracle.Database
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    fabric = {
      source  = "microsoft/fabric"
      version = ">= 1.5"
    }
  }
}

locals {
  # Map of supported connection types → Fabric connector metadata
  # type            = Fabric connector type identifier
  # creation_method = Power Query creation method
  # server_param    = parameter name used for server
  # database_param  = parameter name used for database
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
  }

  connector = local.connector_map[var.connection_type]
}

resource "fabric_connection" "this" {
  display_name      = var.display_name
  connectivity_type = var.connectivity_type
  privacy_level     = var.privacy_level

  # Only set gateway_id for VirtualNetworkGateway / OnPremisesGateway connections
  gateway_id = var.connectivity_type == "ShareableCloud" ? null : var.gateway_id

  connection_details = {
    type            = local.connector.type
    creation_method = local.connector.creation_method

    parameters = concat(
      [
        {
          name  = local.connector.server_param
          value = var.server
        },
        {
          name  = local.connector.database_param
          value = var.database
        }
      ],
      # Oracle needs an additional 'port' parameter when non-default
      var.connection_type == "Oracle" && var.port != null ? [
        { name = "port", value = tostring(var.port) }
      ] : []
    )
  }

credential_details = {
    connection_encryption = var.connection_encryption
    credential_type       = "Basic"
    single_sign_on_type   = "None"
    skip_test_connection  = var.skip_test_connection

    basic_credentials = {
      username = var.username
      password = var.password
    }
  }
}
