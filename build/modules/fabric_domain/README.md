<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fabric"></a> [fabric](#provider\_fabric) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [fabric_domain.child](https://registry.terraform.io/providers/hashicorp/fabric/latest/docs/resources/domain) | resource |
| [fabric_domain.parent](https://registry.terraform.io/providers/hashicorp/fabric/latest/docs/resources/domain) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_child_subdomains"></a> [child\_subdomains](#input\_child\_subdomains) | List of subdomains to create under the parent domain. Required if enable\_child\_domain is true. | `list(string)` | `[]` | no |
| <a name="input_contributors_scope"></a> [contributors\_scope](#input\_contributors\_scope) | The Domain contributors scope. | `string` | `"AdminsOnly"` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Fabric Domain. | `string` | `""` | no |
| <a name="input_enable_child_domain"></a> [enable\_child\_domain](#input\_enable\_child\_domain) | Flag to enable the creation of child domains. | `bool` | `false` | no |
| <a name="input_fabric_domain_child"></a> [fabric\_domain\_child](#input\_fabric\_domain\_child) | Override name for the fabric domain child. If provided, it will be used instead of the generated name. | `string` | `null` | no |
| <a name="input_fabric_domain_parent"></a> [fabric\_domain\_parent](#input\_fabric\_domain\_parent) | Override name for the fabric domain parent. If provided, it will be used instead of the generated name. | `string` | `null` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number for the resource. | `number` | `1` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for resource names. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fabric_domain_child_id"></a> [fabric\_domain\_child\_id](#output\_fabric\_domain\_child\_id) | n/a |
| <a name="output_fabric_domain_parent_id"></a> [fabric\_domain\_parent\_id](#output\_fabric\_domain\_parent\_id) | n/a |
<!-- END_TF_DOCS -->