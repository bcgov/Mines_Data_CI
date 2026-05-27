# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Creates the connection on first apply. On every subsequent apply, it
# queries the Fabric API by display_name to get the existing connection ID.
# The ID is never stored in /tmp between runs — it's always fetched live.
# Credentials are never stored in state.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    external = {
      source  = "hashicorp/external"
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
      credentials          = { credentialType = "WorkspaceIdentity" }
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

# ── Step 1: Ensure connection exists ─────────────────────────────────────────
# Only runs when request_hash changes (config change) or first apply.
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
        --output none 2>/dev/null

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
      fi
    BASH
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      set -e

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none 2>/dev/null

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      CONNECTION_ID=$(curl -s -X GET \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections" | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
conns = data.get('value', [])
match = [c for c in conns if c.get('displayName') == '${self.triggers.display_name}']
print(match[0]['id'] if match else '')
      ")

      if [ -z "$CONNECTION_ID" ]; then
        echo "Connection not found — skipping delete"
        exit 0
      fi

      curl -s -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID"
      echo "Deleted: $CONNECTION_ID"
    BASH
    interpreter = ["bash", "-c"]
  }
}

# ── Step 2: Fetch connection ID from API (runs on every apply) ────────────────
# external data source always runs and returns the current connection ID
# by querying the Fabric API. No file system dependency.
data "external" "connection_id" {
  program = ["bash", "-c", <<-BASH
    set -e

    az login --service-principal \
      --username "$ARM_CLIENT_ID" \
      --password "$ARM_CLIENT_SECRET" \
      --tenant "$ARM_TENANT_ID" \
      --output none 2>/dev/null

    TOKEN=$(az account get-access-token \
      --resource https://api.fabric.microsoft.com \
      --query accessToken -o tsv)

    python3 -c "
import subprocess, json, sys

result = subprocess.run(
    ['curl', '-s', '-X', 'GET',
     '-H', 'Authorization: Bearer ' + '${TOKEN}'.strip(),
     'https://api.fabric.microsoft.com/v1/connections'],
    capture_output=True, text=True
)

data = json.loads(result.stdout)
conns = data.get('value', [])
match = [c for c in conns if c.get('displayName') == '${var.display_name}']
if not match:
    print(json.dumps({'id': ''}))
else:
    print(json.dumps({'id': match[0]['id']}))
"
  BASH
  ]

  depends_on = [null_resource.fabric_connection]
}

# ── Step 3: Grant Owner access ────────────────────────────────────────────────
resource "null_resource" "connection_role_assignment" {
  for_each = toset(var.owner_principal_ids)

  triggers = {
    connection_id = data.external.connection_id.result.id
    principal_id  = each.value
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none 2>/dev/null

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      echo "Granting Owner to ${each.value} on ${self.triggers.connection_id}"
      curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"principal":{"id":"${each.value}","type":"User"},"role":"Owner"}' \
        "https://api.fabric.microsoft.com/v1/connections/${self.triggers.connection_id}/roleAssignments"
      echo "Done"
    BASH
    interpreter = ["bash", "-c"]
  }
}
