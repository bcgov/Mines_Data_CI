# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Creates the Fabric connection via REST API on first apply.
# The connection ID is fetched on every apply via an external data source
# script that reads SP credentials from the runner environment.
#
# State contains: connection ID (just a GUID)
# State does NOT contain: SP credentials, passwords, or other secrets
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

# ── Step 1: Create the connection (only on first apply / config change) ──────
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
import sys,json
data=json.load(sys.stdin)
match=[c for c in data.get('value',[]) if c.get('displayName')=='${var.display_name}']
print(match[0]['id'] if match else '')
")

      if [ -n "$EXISTING" ]; then
        echo "Connection exists: $EXISTING"
      else
        RESPONSE=$(curl -s -X POST \
          -H "Authorization: Bearer $TOKEN" \
          -H "Content-Type: application/json" \
          -d '${local.request_body}' \
          "https://api.fabric.microsoft.com/v1/connections")
        CONNECTION_ID=$(echo "$RESPONSE" | python3 -c "
import sys,json
data=json.load(sys.stdin)
cid=data.get('id',data.get('connectionId',''))
if not cid:
    print('ERROR: '+json.dumps(data),file=sys.stderr); sys.exit(1)
print(cid)
")
        echo "Created: $CONNECTION_ID"
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
import sys,json
data=json.load(sys.stdin)
match=[c for c in data.get('value',[]) if c.get('displayName')=='${self.triggers.display_name}']
print(match[0]['id'] if match else '')
")
      [ -z "$CONNECTION_ID" ] && echo "Not found — skipping" && exit 0
      curl -s -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID"
      echo "Deleted: $CONNECTION_ID"
    BASH
    interpreter = ["bash", "-c"]
  }
}

# ── Step 2: Fetch connection ID from API and store in state ───────────────────
# external data source runs every apply, looks up the connection by display_name,
# and returns the ID. The ID becomes part of Terraform state as a normal
# data source attribute — no /tmp dependency.
data "external" "connection_id" {
  program = ["bash", "${path.module}/get_connection_id.sh"]

  query = {
    display_name = var.display_name
  }

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
      CONNECTION_ID="${data.external.connection_id.result.id}"
      [ -z "$CONNECTION_ID" ] && echo "No connection ID — skipping" && exit 0

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none 2>/dev/null

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      echo "Granting Owner to ${each.value} on $CONNECTION_ID"
      curl -s -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"principal\":{\"id\":\"${each.value}\",\"type\":\"User\"},\"role\":\"Owner\"}" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID/roleAssignments"
      echo "Done"
    BASH
    interpreter = ["bash", "-c"]
  }
}
