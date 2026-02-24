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
| [azurerm_key_vault_access_policy.app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.additional](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_private_endpoint.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Instance_Number"></a> [Instance\_Number](#input\_Instance\_Number) | Instance number appended to generated resource name | `string` | `"00"` | no |
| <a name="input_additional_access_policies"></a> [additional\_access\_policies](#input\_additional\_access\_policies) | Extra KV access policies. `object_id` can be a user, group, or service principal object ID. Unspecified permission lists default to `[]`. | `list(object({ object_id = string, certificate_permissions = optional(list(string), []), key_permissions = optional(list(string), []), secret_permissions = optional(list(string), []), storage_permissions = optional(list(string), []) }))` | `[]` | no |
| <a name="input_certificate_permissions"></a> [certificate\_permissions](#input\_certificate\_permissions) | Certificate permissions granted to the deploying identity / managed identity | `list(string)` | `["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers", "SetIssuers", "DeleteIssuers"]` | no |
| <a name="input_enabled_for_disk_encryption"></a> [enabled\_for\_disk\_encryption](#input\_enabled\_for\_disk\_encryption) | Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault | `bool` | `false` | no |
| <a name="input_enabled_for_template_deployment"></a> [enabled\_for\_template\_deployment](#input\_enabled\_for\_template\_deployment) | Specifies whether Azure Resource Manager is permitted to retrieve secrets from the vault | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | `"dev"` | no |
| <a name="input_ip_rules"></a> [ip\_rules](#input\_ip\_rules) | IP addresses or CIDR blocks permitted to access the Key Vault when `public_network_access_enabled` is `true` | `list(string)` | `[]` | no |
| <a name="input_key_permissions"></a> [key\_permissions](#input\_key\_permissions) | Key permissions granted to the deploying identity / managed identity | `list(string)` | `["Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore", "GetRotationPolicy", "SetRotationPolicy", "Rotate"]` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Optional override for the Key Vault name. If not set, name is generated as `{prefix}-{project}-{suffix}{Instance_Number}` | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region where the Key Vault will be created | `string` | `"canadacentral"` | no |
| <a name="input_managed_identity_delegate"></a> [managed\_identity\_delegate](#input\_managed\_identity\_delegate) | Object ID of a managed identity to grant access to the Key Vault. Defaults to the deploying identity if not set. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Resource name prefix | `string` | n/a | yes |
| <a name="input_private_dns_zone_ids"></a> [private\_dns\_zone\_ids](#input\_private\_dns\_zone\_ids) | Private DNS Zone IDs for `privatelink.vaultcore.azure.net`. Pass the output of the vnet module's `kv_private_dns_zone_id`. | `list(string)` | `[]` | no |
| <a name="input_private_endpoint_enabled"></a> [private\_endpoint\_enabled](#input\_private\_endpoint\_enabled) | Whether to create a private endpoint for the Key Vault. Requires `private_endpoint_subnet_id` to be set. | `bool` | `true` | no |
| <a name="input_private_endpoint_name"></a> [private\_endpoint\_name](#input\_private\_endpoint\_name) | Optional override for the private endpoint name. Defaults to `{kv_name}-pe`. | `string` | `null` | no |
| <a name="input_private_endpoint_subnet_id"></a> [private\_endpoint\_subnet\_id](#input\_private\_endpoint\_subnet\_id) | Subnet ID where the private endpoint will be created. The subnet must have `private_endpoint_network_policies` set to `"Disabled"`. | `string` | `null` | no |
| <a name="input_private_service_connection_name"></a> [private\_service\_connection\_name](#input\_private\_service\_connection\_name) | Optional override for the private service connection name. Defaults to `{kv_name}-psc`. | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"sedw"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether the Key Vault is accessible over the public internet. Should be `false` when using a private endpoint. | `bool` | `false` | no |
| <a name="input_purge_protection_enabled"></a> [purge\_protection\_enabled](#input\_purge\_protection\_enabled) | Prevents the Key Vault from being permanently deleted while enabled | `bool` | `true` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Key Vault | `string` | n/a | yes |
| <a name="input_secret_permissions"></a> [secret\_permissions](#input\_secret\_permissions) | Secret permissions granted to the deploying identity / managed identity | `list(string)` | `["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]` | no |
| <a name="input_sku_family"></a> [sku\_family](#input\_sku\_family) | The SKU family of the Key Vault | `string` | `"A"` | no |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name of the Key Vault | `string` | `"standard"` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Number of days to retain soft-deleted Key Vault resources | `number` | `7` | no |
| <a name="input_storage_permissions"></a> [storage\_permissions](#input\_storage\_permissions) | Storage permissions granted to the deploying identity / managed identity | `list(string)` | `["Get", "Backup", "Delete", "DeleteSAS", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"]` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Resource name suffix | `string` | `"kv"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_virtual_network_subnet_ids"></a> [virtual\_network\_subnet\_ids](#input\_virtual\_network\_subnet\_ids) | Subnet IDs permitted to access the Key Vault via network ACLs | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kv_dns_uri"></a> [kv\_dns\_uri](#output\_kv\_dns\_uri) | URI for KV required to tie resources to several objects |
| <a name="output_kv_id"></a> [kv\_id](#output\_kv\_id) | The ID of the created Azure Key Vault |
| <a name="output_kv_name"></a> [kv\_name](#output\_kv\_name) | The name of the created Azure Key Vault |
<!-- END_TF_DOCS -->