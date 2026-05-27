# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Uses azapi_client_config (to get an OAuth token) + terraform-provider-http
# (to call the Fabric REST API) + null_resource (to manage lifecycle).
#
# Since there is no native Terraform resource for Fabric connections outside
# the preview fabric provider, we use a local-exec provisioner with az rest
# to call the Fabric REST API. The connection ID is extracted from the response
# and stored in a local file, then read back as a data source.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
  }
}

locals {
  connector_map = {
    PostgreSQL = {
      type            = "PostgreSQL"
      creation_method = "PostgreSQL.Database"
      parameters = [
        { dataType = "Text", name = "server",   value = coalesce(var.server,   "") },
        { dataType = "Text", name = "database", value = coalesce(var.database, "") }
      ]
    }
    Oracle = {
      type            = "Oracle"
      creation_method = "Oracle.Database"
      parameters = concat(
        [
          { dataType = "Text", name = "server",   value = coalesce(var.server,   "") },
          { dataType = "Text", name = "database", value = coalesce(var.database, "") }
        ],
        var.port != null ? [{ dataType = "Text", name = "port", value = tostring(var.port) }] : []
      )
    }
    Warehouse = {
      type            = "Warehouse"
      creation_method = "Fabric.Warehouse"
      parameters = [
        { dataType = "Text", name = "workspaceId", value = coalesce(var.workspace_id, "") },
        { dataType = "Text", name = "artifactId",  value = coalesce(var.warehouse_id, "") }
      ]
    }
  }

  connector = local.connector_map[var.connection_type]

  request_body = var.connection_type == "Warehouse" ? jsonencode({
    displayName      = var.display_name
    connectivityType = var.connectivity_type
    privacyLevel     = var.privacy_level
    connectionDetails = {
      type           = local.connector.type
      creationMethod = local.connector.creation_method
      parameters     = local.connector.parameters
    }
    credentialDetails = {
      singleSignOnType     = "None"
      connectionEncryption = "NotEncrypted"
      skipTestConnection   = var.skip_test_connection
      credentials = {
        credentialType = "OAuth2"
      }
    }
  }) : jsonencode({
    displayName      = var.display_name
    connectivityType = var.connectivity_type
    privacyLevel     = var.privacy_level
    gatewayId        = var.connectivity_type != "ShareableCloud" ? var.gateway_id : null
    connectionDetails = {
      type           = local.connector.type
      creationMethod = local.connector.creation_method
      parameters     = local.connector.parameters
    }
    credentialDetails = {
      singleSignOnType     = "None"
      connectionEncryption = var.connection_encryption
      skipTestConnection   = var.skip_test_connection
      credentials = {
        credentialType = "Basic"
        username       = coalesce(var.username, "")
        password       = coalesce(var.password, "")
      }
    }
  })

  # File to store the connection ID between runs
  connection_id_file = "${path.module}/.connection_id_${var.display_name}.txt"
}

# ── Create the connection via Fabric REST API ─────────────────────────────────
resource "null_resource" "fabric_connection" {
  triggers = {
    display_name      = var.display_name
    connection_type   = var.connection_type
    connectivity_type = var.connectivity_type
    server            = coalesce(var.server, "")
    database          = coalesce(var.database, "")
    workspace_id      = coalesce(var.workspace_id, "")
    warehouse_id      = coalesce(var.warehouse_id, "")
    password_version  = var.password_version
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e

      # Get Fabric API token using the SP credentials from environment
      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      BODY='${local.request_body}'

      # Check if connection already exists with this display name
      EXISTING=$(curl -s -X GET \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.fabric.microsoft.com/v1/connections" | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
conns = data.get('value', [])
match = [c for c in conns if c.get('displayName') == '${var.display_name}']
print(match[0]['id'] if match else '')
      ")

      if [ -n "$EXISTING" ]; then
        echo "Connection already exists: $EXISTING"
        echo -n "$EXISTING" > '${local.connection_id_file}'
      else
        RESPONSE=$(curl -s -X POST \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d "$BODY" \
          "https://api.fabric.microsoft.com/v1/connections")

        CONNECTION_ID=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data.get('id', data.get('connectionId', '')))
        ")

        if [ -z "$CONNECTION_ID" ]; then
          echo "ERROR: Failed to create connection. Response: $RESPONSE"
          exit 1
        fi

        echo "Created connection: $CONNECTION_ID"
        echo -n "$CONNECTION_ID" > '${local.connection_id_file}'
      fi
    BASH
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      set -e
      if [ ! -f '${local.connection_id_file}' ]; then
        echo "No connection ID file found — nothing to delete"
        exit 0
      fi

      CONNECTION_ID=$(cat '${local.connection_id_file}')
      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      curl -s -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID"

      rm -f '${local.connection_id_file}'
      echo "Deleted connection: $CONNECTION_ID"
    BASH
    interpreter = ["bash", "-c"]
  }
}

# ── Read back the connection ID from file ─────────────────────────────────────
data "local_file" "connection_id" {
  filename   = local.connection_id_file
  depends_on = [null_resource.fabric_connection]
}
