<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_fabric"></a> [fabric](#requirement\_fabric) | 1.10.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fabric.auth"></a> [fabric.auth](#provider\_fabric.auth) | 1.10.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [fabric_warehouse.this_warehouse](https://registry.terraform.io/providers/microsoft/fabric/1.10.0/docs/resources/warehouse) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | Description of the Fabric Workspace. | `string` | `""` | no |
| <a name="input_fabric_warehouse"></a> [fabric\_warehouse](#input\_fabric\_warehouse) | Name of fabric warehouse. | `string` | `null` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number for the resource. | `number` | `1` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for resource names. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name. | `string` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | id of fabric workspace. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_warehouse"></a> [warehouse](#output\_warehouse) | n/a |
| <a name="output_warehouse_connection_string"></a> [warehouse\_connection\_string](#output\_warehouse\_connection\_string) | The SQL connection string for the warehouse. |
| <a name="output_warehouse_id"></a> [warehouse\_id](#output\_warehouse\_id) | n/a |
<!-- END_TF_DOCS -->