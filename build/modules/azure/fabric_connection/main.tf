# ─────────────────────────────────────────────────────────────────────────────
# Fabric Connection — PostgreSQL, Oracle, or Warehouse
#
# Creates the connection via Fabric REST API on first apply.
# The connection ID is stored in triggers in the state file (committed to repo)
# so it persists across CI runs. Credentials never enter state.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
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

# ── Step 1: Create or fetch the connection ────────────────────────────────────
# Only re-runs when request_hash changes.
# Writes the connection ID into terraform.tfstate directly so it
# persists in state and is readable as an output.
resource "null_resource" "fabric_connection" {
  triggers = {
    display_name     = var.display_name
    connection_type  = var.connection_type
    password_version = tostring(var.password_version)
    request_hash     = sha256(local.request_body)
    # Seeded as "none" so the key always exists in the map.
    # Overwritten with the real ID by the provisioner patching the state file.
    connection_id    = "none"
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
        CONNECTION_ID="$EXISTING"
        echo "Connection exists: $CONNECTION_ID"
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

      # Patch the state file to store connection_id in triggers
      python3 - "$CONNECTION_ID" "${var.display_name}" <<'PYEOF'
import json, glob, sys

connection_id = sys.argv[1]
display_name  = sys.argv[2]

state_files = glob.glob('terraform.tfstate')
if not state_files:
    print("ERROR: terraform.tfstate not found", file=sys.stderr)
    sys.exit(1)

with open(state_files[0]) as f:
    state = json.load(f)

updated = False
for res in state.get('resources', []):
    if res.get('type') == 'null_resource' and res.get('name') == 'fabric_connection':
        for inst in res.get('instances', []):
            triggers = inst.get('attributes', {}).get('triggers', {})
            if triggers.get('display_name') == display_name:
                triggers['connection_id'] = connection_id
                updated = True

with open(state_files[0], 'w') as f:
    json.dump(state, f, indent=2)

print("State patched — connection_id:", connection_id if updated else "NOT FOUND")
if not updated:
    sys.exit(1)
PYEOF
    BASH
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-BASH
      set -e
      # connection_id is stored in triggers in state — always present as "none" or a real ID
      CONNECTION_ID="${self.triggers["connection_id"]}"
      if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "none" ]; then
        echo "No connection ID in state — skipping delete"
        exit 0
      fi

      az login --service-principal \
        --username "$ARM_CLIENT_ID" \
        --password "$ARM_CLIENT_SECRET" \
        --tenant "$ARM_TENANT_ID" \
        --output none 2>/dev/null

      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken -o tsv)

      curl -s -X DELETE \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/connections/$CONNECTION_ID"
      echo "Deleted: $CONNECTION_ID"
    BASH
    interpreter = ["bash", "-c"]
  }
}

# ── Step 2: Grant Owner access ────────────────────────────────────────────────
resource "null_resource" "connection_role_assignment" {
  for_each = toset(var.owner_principal_ids)

  triggers = {
    connection_id = null_resource.fabric_connection.triggers["connection_id"]
    principal_id  = each.value
  }

  provisioner "local-exec" {
    command = <<-BASH
      set -e
      CONNECTION_ID="${null_resource.fabric_connection.triggers["connection_id"]}"
      if [ -z "$CONNECTION_ID" ] || [ "$CONNECTION_ID" = "none" ]; then
        echo "No connection ID yet — skipping role assignment"
        exit 0
      fi

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

  depends_on = [null_resource.fabric_connection]
}
