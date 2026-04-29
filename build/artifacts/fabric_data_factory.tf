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

# ── 2. Key Vault ──────────────────────────────────────────────────────────────

module "key_vault_adf" {
  source = "../modules/azure/key_vaults"

  prefix                   = "mines"
  project                  = "fabric"
  suffix                   = "kv"
  Instance_Number          = "01"
  private_endpoint_enabled = false
  resource_group_name      = module.resource_group_adf.rg_name
  location                 = "canadacentral"

  sku_name                        = "standard"
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 1
  purge_protection_enabled        = false
  public_network_access_enabled   = false
  enable_rbac_assignments         = true

  # Grant the ADF managed identity Key Vault access after ADF is created
  # Done via additional_access_policies referencing the ADF principal_id output
  # See module "data_factory" below — access policy added post-creation
  additional_access_policies = []
  depends_on                 = [module.resource_group_adf]
}

# ── 3. Azure Data Factory ─────────────────────────────────────────────────────

module "data_factory" {
  source = "../modules/azure/data_factory_base"

  prefix          = "mines"
  project         = "fabric"
  Instance_Number = "01"

  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"

  # Reference the KV created above
  key_vault_name = module.key_vault_adf.kv_name

  public_network_enabled          = true
  managed_virtual_network_enabled = true
  virtual_network_enabled         = true

  compute_type     = "General"
  core_count       = 8
  time_to_live_min = 10
  cleanup_enabled  = true

  action_group_name                = "mines-fabric-adf-alerts"
  email_address                    = "test@gov.bc.ca"
  enable_action_group_notification = true


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



  depends_on = [module.key_vault_adf]
}

# ── 4. Grant ADF managed identity access to Key Vault ────────────────────────
# The ADF system-assigned identity is only known after ADF is created,
# so this role assignment is done as a separate resource after the fact.

resource "azurerm_role_assignment" "adf_kv_secrets_user" {
  scope                = module.key_vault_adf.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.data_factory.adf_identity_id[0].principal_id

  depends_on = [module.data_factory, module.key_vault_adf]
}

# ── 5. Mount ADF into the Fabric workspace ────────────────────────────────────
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
