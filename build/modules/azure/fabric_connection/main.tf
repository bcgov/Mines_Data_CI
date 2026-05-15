terraform {
  required_version = ">= 1.6"

  required_providers {
    fabric = {
      source                = "microsoft/fabric"
      version               = ">= 1.5"
      configuration_aliases = [fabric.auth]
    }
  }
}

locals {
  # Map of supported connection types → Fabric connector metadata
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

  # Gateway is required for VirtualNetworkGateway and OnPremisesGateway
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
      # Oracle gets an optional port parameter
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
      username            = var.username
      password_wo         = var.password
      password_wo_version = var.password_version
    }
  }
}
