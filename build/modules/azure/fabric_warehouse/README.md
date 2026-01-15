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
| [fabric_warehouse.this_warehouse](https://registry.terraform.io/providers/hashicorp/fabric/latest/docs/resources/warehouse) | resource |
| [fabric_workspace.this_workspace](https://registry.terraform.io/providers/hashicorp/fabric/latest/docs/data-sources/workspace) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Description of the Fabric Workspace. | `string` | `""` | no |
| <a name="input_fabric_warehouse"></a> [fabric\_warehouse](#input\_fabric\_warehouse) | Name of fabric warehouse. | `string` | `null` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number for the resource. | `number` | `1` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for resource names. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name. | `string` | n/a | yes |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Name of fabric workspace. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_warehouse_id"></a> [warehouse\_id](#output\_warehouse\_id) | n/a |
<!-- END_TF_DOCS -->