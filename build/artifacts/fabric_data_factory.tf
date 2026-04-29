# =============================================================================
# build/artifacts/adf.tf
# =============================================================================

# ── 1. Resource Group ─────────────────────────────────────────────────────────

module "resource_group_adf" {
  source = "../modules/azure/resource_groups"

  prefix          = "mines"
  project         = "fabric"
  suffix          = "rg"
  Instance_Number = "02"
  location        = "canadacentral"
}

# ── 2. Azure Data Factory ─────────────────────────────────────────────────────

module "data_factory" {
  source = "../modules/data_factory_base"

  prefix          = "mines"
  project         = "fabric"
  Instance_Number = "01"

  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"
  key_vault_name      = var.KEY_VAULT_NAME

  public_network_enabled          = true
  managed_virtual_network_enabled = true
  virtual_network_enabled         = true

  compute_type     = "General"
  core_count       = 8
  time_to_live_min = 10
  cleanup_enabled  = true

  action_group_name                = "mines-fabric-adf-alerts"
  email_address                    = var.ALERT_EMAIL
  enable_action_group_notification = true

  # pep_storage_account_id = var.ONELAKE_STORAGE_ACCOUNT_ID

  global_parameters = [
    {
      name  = "fabric_workspace_id"
      type  = "String"
      value = module.fabric_workspace_01.workspace_id
    },
    {
      name  = "environment"
      type  = "String"
      value = var.ENVIRONMENT
    }
  ]

  tags = var.tags
}

# ── 3. Mount ADF into the Fabric workspace ────────────────────────────────────
# Calls the Fabric REST API to attach the ADF instance to the workspace.
# Idempotent — checks if already mounted before calling the API.
# Re-runs only if the ADF resource ID or workspace ID changes.

resource "null_resource" "mount_adf_to_fabric" {
  depends_on = [module.data_factory]

  triggers = {
    adf_id       = module.data_factory.adf_id
    workspace_id = module.fabric_workspace_01.workspace_id
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      TOKEN=$(az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken \
        --output tsv)

      WORKSPACE_ID="${module.fabric_workspace_01.workspace_id}"
      ADF_ID="${module.data_factory.adf_id}"
      ADF_NAME="${module.data_factory.adf_name}"

      echo "Checking if ADF is already mounted in workspace $WORKSPACE_ID..."
      EXISTING=$(curl -s \
        -H "Authorization: Bearer $TOKEN" \
        "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/items" \
        | jq -r --arg adf_id "$ADF_ID" \
          '.value[] | select(.type == "AzureDataFactory" and .properties.linkedAdfResourceId == $adf_id) | .id')

      if [[ -n "$EXISTING" ]]; then
        echo "ADF already mounted (item id: $EXISTING) — skipping"
        exit 0
      fi

      echo "Mounting ADF '$ADF_NAME' to Fabric workspace..."
      STATUS=$(curl -s -o /tmp/adf_mount_response.json -w "%%{http_code}" \
        -X POST \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"displayName\": \"$ADF_NAME\",
          \"type\": \"AzureDataFactory\",
          \"properties\": {
            \"linkedAdfResourceId\": \"$ADF_ID\"
          }
        }" \
        "https://api.fabric.microsoft.com/v1/workspaces/$WORKSPACE_ID/items")

      echo "HTTP status: $STATUS"
      cat /tmp/adf_mount_response.json | jq . 2>/dev/null || cat /tmp/adf_mount_response.json

      if [[ "$STATUS" == "200" || "$STATUS" == "201" || "$STATUS" == "202" ]]; then
        echo "ADF mounted successfully"
      else
        echo "ERROR: Mount failed (HTTP $STATUS)"
        exit 1
      fi
    EOT
  }
}
