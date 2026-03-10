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
| [azurerm_private_dns_zone.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_subnet.subnets](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | Address space for the VNet | `list(string)` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name | `string` | `"dev"` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number | `string` | `"00"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region | `string` | `"canadacentral"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Resource name prefix | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name | `string` | `"fabric"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group to deploy the VNet into | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnets to create | <pre>map(object({<br>    address_prefixes                  = list(string)<br>    private_endpoint_network_policies = optional(string, "Enabled")<br>    service_endpoints                 = optional(list(string), [])<br>  }))</pre> | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Resource name suffix | `string` | `"vnet"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the Azure Resource Group | `map(string)` | <pre>{<br>  "application_environment": "dev",<br>  "client_code": "",<br>  "deployment_automation": "Terraform",<br>  "deployment_automation_version": "v0.1",<br>  "expense_authority": "",<br>  "information_security_classification": "protected_e",<br>  "ministry_name_prefix": "citz",<br>  "program_area": "permitting",<br>  "project_number": "",<br>  "responsibility_centre": "",<br>  "service_line": ""<br>}</pre> | no |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Optional override for the VNet name | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kv_private_dns_zone_id"></a> [kv\_private\_dns\_zone\_id](#output\_kv\_private\_dns\_zone\_id) | The ID of the Key Vault private DNS zone (privatelink.vaultcore.azure.net) |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet name to subnet ID |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The ID of the virtual network |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The name of the virtual network |
<!-- END_TF_DOCS -->