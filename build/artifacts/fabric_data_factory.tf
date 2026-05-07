# =============================================================================
# build/artifacts/adf.tf
# =============================================================================

module "resource_group_adf" {
  source = "../modules/azure/resource_groups"

  prefix          = "mines"
  project         = "fabric"
  suffix          = "rg"
  Instance_Number = "02"
  location        = "canadacentral"
}

module "key_vault_adf" {
  source = "../modules/azure/key_vaults"

  prefix                          = "mines"
  project                         = "fabric"
  suffix                          = "kv"
  Instance_Number                 = "01"
  resource_group_name             = module.resource_group_adf.rg_name
  location                        = "canadacentral"
  sku_name                        = "standard"
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  public_network_access_enabled   = false
  enable_rbac_assignments         = true

  private_endpoint_enabled   = false
  ip_rules                   = []
  virtual_network_subnet_ids = []

  # Do not add ADF identity here.
  # ADF identity is only known after ADF is created.
  additional_access_policies = []

  depends_on = [module.resource_group_adf]
}

module "data_factory" {
  source = "../modules/azure/data_factory_base"

  prefix          = "mines"
  project         = "fabric"
  Instance_Number = "01"

  resource_group_name = module.resource_group_adf.rg_name
  location            = "canadacentral"

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

resource "azurerm_role_assignment" "adf_kv_secrets_user" {
  scope                = module.key_vault_adf.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.data_factory.adf_identity_id[0].principal_id

  depends_on = [
    module.key_vault_adf,
    module.data_factory
  ]
}

resource "null_resource" "mount_adf_to_fabric" {
  depends_on = [
    module.data_factory,
    azurerm_role_assignment.adf_kv_secrets_user
  ]

  triggers = {
    adf_id       = module.data_factory.adf_id
    adf_name     = module.data_factory.adf_name
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
import os, sys, json, base64
import urllib.request, urllib.parse, urllib.error

client_id     = os.environ["CLIENT_ID"]
client_secret = os.environ["CLIENT_SECRET"]
tenant_id     = os.environ["TENANT_ID"]
workspace_id  = os.environ["WORKSPACE_ID"]
adf_id        = os.environ["ADF_ID"]
adf_name      = os.environ["ADF_NAME"]

def encode_payload(obj):
    raw = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    return base64.b64encode(raw).decode("utf-8")

def request_json(url, method="GET", body=None):
    req = urllib.request.Request(
        url,
        data=body,
        headers=headers,
        method=method
    )
    with urllib.request.urlopen(req) as response:
        text = response.read().decode("utf-8")
        return response.status, response.headers, json.loads(text) if text else {}

token_url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token"
token_body = urllib.parse.urlencode({
    "grant_type": "client_credentials",
    "client_id": client_id,
    "client_secret": client_secret,
    "scope": "https://api.fabric.microsoft.com/.default"
}).encode("utf-8")

token_req = urllib.request.Request(token_url, data=token_body, method="POST")

with urllib.request.urlopen(token_req) as token_response:
    token = json.loads(token_response.read().decode("utf-8"))["access_token"]

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

list_url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/mountedDataFactories"

try:
    _, _, list_response = request_json(list_url)
    existing = [
        item for item in list_response.get("value", [])
        if item.get("displayName") == adf_name
    ]

    if existing:
        print(f"ADF already mounted in Fabric. Item id: {existing[0].get('id')}")
        sys.exit(0)

except urllib.error.HTTPError as e:
    error_body = e.read().decode("utf-8")
    print(f"WARNING: Could not list mounted data factories. HTTP {e.code}: {error_body}")

definition = {
    "parts": [
        {
            "path": "mountedDataFactory-content.json",
            "payload": encode_payload({
                "dataFactoryResourceId": adf_id
            }),
            "payloadType": "InlineBase64"
        }
    ]
}

create_body = json.dumps({
    "displayName": adf_name,
    "definition": definition
}).encode("utf-8")

create_url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/mountedDataFactories"

try:
    status, response_headers, response_body = request_json(
        create_url,
        method="POST",
        body=create_body
    )

    if status in (200, 201):
        print(f"ADF mounted successfully. HTTP {status}")
        sys.exit(0)

    if status == 202:
        print("ADF mount accepted as long-running operation.")
        operation_location = response_headers.get("Location") or response_headers.get("Operation-Location")
        if operation_location:
            print(f"Operation location: {operation_location}")
        sys.exit(0)

    print(f"ADF mount returned HTTP {status}: {response_body}")
    sys.exit(0)

except urllib.error.HTTPError as e:
    error_body = e.read().decode("utf-8")

    if e.code == 409:
        print("ADF mount already exists or conflicts with an existing item. Skipping.")
        sys.exit(0)

    if e.code == 400 and "OperationNotSupportedForItem" in error_body:
        print("WARNING: Fabric rejected MountedDataFactory creation. ADF was NOT mounted.")
        print("Check that Azure Data Factory in Fabric preview is enabled and that the workspace is on supported Fabric capacity.")
        sys.exit(0)

    print(f"ERROR: MountedDataFactory creation failed. HTTP {e.code}: {error_body}", file=sys.stderr)
    sys.exit(1)
PYEOF
  }
}