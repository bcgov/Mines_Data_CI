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
  prefix          = "mines"
  project         = "fabric"
  suffix          = "kv"
  Instance_Number = "01"
  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"
  sku_name                        = "standard"
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  public_network_access_enabled   = false
  enable_rbac_assignments         = true

  # ADF connects to KV via managed private endpoint — no public access needed
  private_endpoint_enabled        = false
  ip_rules                        = []
  virtual_network_subnet_ids      = []

  # Grant the ADF managed identity Key Vault access after ADF is created
  # Done via additional_access_policies referencing the ADF principal_id output
  # See module "data_factory" below — access policy added post-creation
  additional_access_policies = []


  depends_on = [module.resource_group_adf]
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

  public_network_enabled          = false
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
# Uses MountedDataFactory item type per the official Fabric REST API docs:
# https://learn.microsoft.com/en-us/rest/api/fabric/articles/item-management/item-management-overview
# MountedDataFactory supports: Create with payload, Service principal auth ✅

resource "null_resource" "mount_adf_to_fabric" {
  depends_on = [module.data_factory]

  triggers = {
    adf_id       = module.data_factory.adf_id
    workspace_id = module.fabric_workspace_01.workspace_id
  }

  provisioner "local-exec" {
    interpreter = ["python3", "-c"]
    environment = {
      WORKSPACE_ID  = module.fabric_workspace_01.workspace_id
      ADF_ID        = module.data_factory.adf_id
      ADF_NAME      = module.data_factory.adf_name
      CLIENT_ID     = var.ARM_CLIENT_ID
      CLIENT_SECRET = var.ARM_CLIENT_SECRET
      TENANT_ID     = var.ARM_TENANT_ID
    }
    command = <<-PYEOF
import os, sys, json, urllib.request, urllib.parse

client_id     = os.environ["CLIENT_ID"]
client_secret = os.environ["CLIENT_SECRET"]
tenant_id     = os.environ["TENANT_ID"]
workspace_id  = os.environ["WORKSPACE_ID"]
adf_id        = os.environ["ADF_ID"]
adf_name      = os.environ["ADF_NAME"]

# Step 1: Get Fabric access token via client credentials flow
token_url  = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
token_data = urllib.parse.urlencode({
    "grant_type":    "client_credentials",
    "client_id":     client_id,
    "client_secret": client_secret,
    "scope":         "https://api.fabric.microsoft.com/.default"
}).encode()
req      = urllib.request.Request(token_url, data=token_data, method="POST")
response = urllib.request.urlopen(req)
token    = json.loads(response.read())["access_token"]
print("Token obtained")

headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# Step 2: Check if ADF is already mounted
list_url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/items"
req      = urllib.request.Request(list_url, headers=headers)
items    = json.loads(urllib.request.urlopen(req).read()).get("value", [])
existing = [i for i in items if i.get("type") == "MountedDataFactory" and i.get("displayName") == adf_name]
if existing:
    print(f"ADF already mounted (item id: {existing[0]['id']}) - skipping")
    sys.exit(0)

# Step 3: Mount ADF using MountedDataFactory item type
# Ref: https://learn.microsoft.com/en-us/rest/api/fabric/articles/item-management/item-management-overview
body = json.dumps({
    "displayName":    adf_name,
    "type":           "MountedDataFactory",
    "creationPayload": {"linkedAdfResourceId": adf_id}
}).encode()
req = urllib.request.Request(list_url, data=body, headers=headers, method="POST")
try:
    response = urllib.request.urlopen(req)
    print(f"ADF mounted successfully (HTTP {response.status})")
except urllib.error.HTTPError as e:
    error_body = e.read().decode()
    print(f"ERROR: Mount failed (HTTP {e.code}): {error_body}", file=sys.stderr)
    sys.exit(1)
    PYEOF
  }
}
