# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Uses null_resource + local-exec to call the Fabric Connections REST API.
# Auth uses ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID from the
# runner's environment — these are already set by the CI pipeline's env:
# block and inherited by child processes. No credentials in Terraform state.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
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
        { dataType = "Text", name = "server",   value = var.server != null ? var.server : "" },
        { dataType = "Text", name = "database", value = var.database != null ? var.database : "" }
      ]
    }
    Oracle = {
      type            = "Oracle"
      creation_method = "Oracle.Database"
      parameters = concat(
        [
          { dataType = "Text", name = "server",   value = var.server != null ? var.server : "" },
          { dataType = "Text", name = "database", value = var.database != null ? var.database : "" }
        ],
        var.port != null ? [{ dataType = "Text", name = "port", value = tostring(var.port) }] : []
      )
    }
    Warehouse = {
      type            = "Warehouse"
      creation_method = "Fabric.Warehouse"
      parameters = [
        { dataType = "Text", name = "workspaceId", value = var.workspace_id != null ? var.workspace_id : "" },
        { dataType = "Text", name = "artifactId",  value = var.warehouse_id != null ? var.warehouse_id : "" }
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
        username       = var.username != null ? var.username : ""
        password       = var.password != null ? var.password : ""
      }
    }
  })
}

resource "null_resource" "fabric_connection" {
  triggers = {
    display_name     = var.display_name
    connection_type  = var.connection_type
    password_version = tostring(var.password_version)
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e

      # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID are inherited
      # from the CI runner environment — no Terraform variables needed
      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      # Check if connection already exists
      EXISTING=$(curl -s -X GET \
        -H "Authorization: Bearer $TOKEN" \
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
        echo -n "$EXISTING" > /tmp/fabric_conn_${var.display_name}.txt
      else
        RESPONSE=$(curl -s -w "\n%%HTTP_CODE%%:%{http_code}" -X POST \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '${local.request_body}' \
          "https://api.fabric.microsoft.com/v1/connections")

        HTTP_CODE=$(echo "$RESPONSE" | grep '%%HTTP_CODE%%' | cut -d: -f2)
        BODY=$(echo "$RESPONSE" | grep -v '%%HTTP_CODE%%')

        CONNECTION_ID=$(echo "$BODY" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cid = data.get('id', data.get('connectionId', ''))
if not cid:
    print('ERROR: ' + json.dumps(data), file=sys.stderr)
    sys.exit(1)
print(cid)
        ")

        echo "Created connection: $CONNECTION_ID"
        echo -n "$CONNECTION_ID" > /tmp/fabric_conn_${var.display_name}.txt
      fi
    BASH
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      set -e

      CONN_FILE="/tmp/fabric_conn_${self.triggers.display_name}.txt"
      if [ ! -f "$CONN_FILE" ]; then
        echo "No connection ID file — skipping delete"
        exit 0
      fi
      CONNECTION_ID=$(cat "$CONN_FILE")
      if [ -z "$CONNECTION_ID" ]; then
        echo "Empty connection ID — skipping delete"
        exit 0
      fi

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      curl -s -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID"

      rm -f "$CONN_FILE"
      echo "Deleted connection: $CONNECTION_ID"
    BASH
    interpreter = ["bash", "-c"]
  }
}

data "local_file" "connection_id" {
  filename   = "/tmp/fabric_conn_${var.display_name}.txt"
  depends_on = [null_resource.fabric_connection]
}
