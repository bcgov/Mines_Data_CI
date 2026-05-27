# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Uses null_resource + local-exec to call the Fabric Connections REST API.
# ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID are read from the
# runner environment — no credentials in Terraform state.
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
      type            = "SQL"
      creation_method = "SQL"
      parameters = [
        { dataType = "Text", name = "server",   value = var.server != null ? var.server : "" },
        { dataType = "Text", name = "database", value = var.database != null ? var.database : "" }
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
        credentialType = "WorkspaceIdentity"
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

  conn_file = "/tmp/fabric_conn_${var.display_name}.txt"
}

# ── Step 1: Create the connection ─────────────────────────────────────────────
resource "null_resource" "fabric_connection" {
  triggers = {
    display_name     = var.display_name
    connection_type  = var.connection_type
    password_version = tostring(var.password_version)
    request_hash     = sha256(local.request_body)
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

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
        echo -n "$EXISTING" > ${local.conn_file}
      else
        RESPONSE=$(curl -s -X POST \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '${local.request_body}' \
          "https://api.fabric.microsoft.com/v1/connections")

        CONNECTION_ID=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
cid = data.get('id', data.get('connectionId', ''))
if not cid:
    print('ERROR: ' + json.dumps(data), file=sys.stderr)
    sys.exit(1)
print(cid)
        ")
        echo "Created connection: $CONNECTION_ID"
        echo -n "$CONNECTION_ID" > ${local.conn_file}
      fi
    BASH
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      set -e
      if [ ! -f "${self.triggers.display_name}" ]; then
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
      fi
    BASH
    interpreter = ["bash", "-c"]
  }
}

# ── Step 2: Read connection ID ────────────────────────────────────────────────
data "local_file" "connection_id" {
  filename   = local.conn_file
  depends_on = [null_resource.fabric_connection]
}

# ── Step 3: Grant Owner access to each principal ──────────────────────────────
resource "null_resource" "connection_role_assignment" {
  for_each = toset(var.owner_principal_ids)

  triggers = {
    connection_id = trimspace(data.local_file.connection_id.content)
    principal_id  = each.value
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      echo "Granting Owner access to principal: ${each.value}"

      curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"principal":{"id":"${each.value}","type":"User"},"role":"Owner"}' \
        "https://api.fabric.microsoft.com/v1/connections/${self.triggers.connection_id}/roleAssignments"

      echo "Role assignment complete"
    BASH
    interpreter = ["bash", "-c"]
  }
}
