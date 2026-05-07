<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_private_endpoint.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_role_assignment.additional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.self_user_access_admin_kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Instance_Number"></a> [Instance\_Number](#input\_Instance\_Number) | Project name | `string` | `"00"` | no |
| <a name="input_additional_access_policies"></a> [additional\_access\_policies](#input\_additional\_access\_policies) | List of additional RBAC role assignments. role\_definition\_name should be a built-in KV role e.g. 'Key Vault Secrets User', 'Key Vault Secrets Officer', 'Key Vault Crypto Officer', 'Key Vault Administrator'. | <pre>list(object({<br>    object_id            = string<br>    role_definition_name = string<br>  }))</pre> | `[]` | no |
| <a name="input_certificate_permissions"></a> [certificate\_permissions](#input\_certificate\_permissions) | List of certificate permissions | `list(string)` | <pre>[<br>  "Get",<br>  "List",<br>  "Update",<br>  "Create",<br>  "Import",<br>  "Delete",<br>  "Recover",<br>  "Backup",<br>  "Restore",<br>  "ManageContacts",<br>  "ManageIssuers",<br>  "GetIssuers",<br>  "ListIssuers",<br>  "SetIssuers",<br>  "DeleteIssuers"<br>]</pre> | no |
| <a name="input_enable_rbac_assignments"></a> [enable\_rbac\_assignments](#input\_enable\_rbac\_assignments) | Whether to create role assignments for the deploying identity and self user access admin. Disable if the Service Principal lacks Microsoft.Authorization/roleAssignments/write. | `bool` | `false` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault | `bool` | `false` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | `"-"` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | One or more IP Addresses, or CIDR Blocks which should be able to access the Key Vault when public network access is enabled. | `list(string)` | `[]` | no |
| <a name="input_key_permissions"></a> [key\_permissions](#input\_key\_permissions) | List of key permissions | `list(string)` | <pre>[<br>  "Get",<br>  "List",<br>  "Update",<br>  "Create",<br>  "Import",<br>  "Delete",<br>  "Recover",<br>  "Backup",<br>  "Restore",<br>  "GetRotationPolicy",<br>  "SetRotationPolicy",<br>  "Rotate"<br>]</pre> | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | The name of the Key Vault | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location where the Key Vault should be created | `string` | `"eastus2"` | no |
| <a name="input_managed_identity_delegate"></a> [managed\_identity\_delegate](#input\_managed\_identity\_delegate) | Id of the managed identity to give access to the keyvault | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Resource name prefix | `string` | n/a | yes |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | Private DNS Zone IDs for Key Vault (privatelink.vaultcore.azure.net). Optional. | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_enabled"></a> [private\_endpoint\_enabled](#input\_private\_endpoint\_enabled) | Whether to create a private endpoint for the Key Vault. | `bool` | `true` | no |
| <a name="input_private_endpoint_name"></a> [private\_endpoint\_name](#input\_private\_endpoint\_name) | Optional override for private endpoint name. | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | Subnet ID where the KV private endpoint will be created. | `string` | `null` | no |
| <a name="input_private_service_connection_name"></a> [private\_service\_connection\_name](#input\_private\_service\_connection\_name) | Optional override for private service connection name. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"fabric"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | specifies if the kv should be publicly available on network | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Protect KV from purge | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Key Vault | `string` | n/a | yes |
| <a name="input_secret_permissions"></a> [secret\_permissions](#input\_secret\_permissions) | List of secret permissions | `list(string)` | <pre>[<br>  "Get",<br>  "List",<br>  "Set",<br>  "Delete",<br>  "Recover",<br>  "Backup",<br>  "Restore"<br>]</pre> | no |
| <a name="input_sku_family"></a> [sku\_family](#input\_sku\_family) | The SKU family of the Key Vault | `string` | `"A"` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name of the Key Vault | `string` | `"standard"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Protect KV from purge | `number` | `7` | no |
| <a name="input_storage_permissions"></a> [storage\_permissions](#input\_storage\_permissions) | List of secret permissions | `list(string)` | <pre>[<br>  "Get",<br>  "Backup",<br>  "Delete",<br>  "DeleteSAS",<br>  "GetSAS",<br>  "List",<br>  "ListSAS",<br>  "Purge",<br>  "Recover",<br>  "RegenerateKey",<br>  "Restore",<br>  "Set",<br>  "SetSAS",<br>  "Update"<br>]</pre> | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Resource name suffix | `string` | `"kv"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Azure Resource Group | `map(string)` | <pre>{<br>  "application_environment": "dev",<br>  "client_code": "",<br>  "deployment_automation": "Terraform",<br>  "deployment_automation_version": "v0.1",<br>  "expense_authority": "",<br>  "information_security_classification": "protected_e",<br>  "ministry_name_prefix": "citz",<br>  "program_area": "permitting",<br>  "project_number": "",<br>  "responsibility_centre": "",<br>  "service_line": ""<br>}</pre> | no |
| <a name="input_virtual_network_subnet_ids"></a> [virtual\_network\_subnet\_ids](#input\_virtual\_network\_subnet\_ids) | One or more Subnet IDs which should be able to access this Key Vault. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kv_dns_uri"></a> [kv\_dns\_uri](#output\_kv\_dns\_uri) | URI for KV required to tie resources to several objects |
| <a name="output_kv_id"></a> [kv\_id](#output\_kv\_id) | The ID of the created Azure Key Vault |
| <a name="output_kv_name"></a> [kv\_name](#output\_kv\_name) | The name of the created Azure Key Vault |
<!-- END_TF_DOCS -->