<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_fabric"></a> [fabric](#requirement\_fabric) | 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_fabric.auth"></a> [fabric.auth](#provider\_fabric.auth) | 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [fabric_gateway.this](https://registry.terraform.io/providers/microsoft/fabric/1.6.0/docs/resources/gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_id"></a> [capacity\_id](#input\_capacity\_id) | ID of the Fabric Capacity to assign to the Virtual Network Gateway. Required for VirtualNetwork type. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for the gateway name. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name for the gateway. | `string` | n/a | yes |
| <a name="input_virtual_network_azure_resource"></a> [virtual\_network\_azure\_resource](#input\_virtual\_network\_azure\_resource) | Azure Virtual Network resource details for the gateway. All fields are required. | <pre>object({<br>    resource_group_name  = string<br>    virtual_network_name = string<br>    subnet_name          = string<br>    subscription_id      = string<br>  })</pre> | n/a | yes |
| <a name="input_gateway_name"></a> [gateway\_name](#input\_gateway\_name) | Optional gateway name to override the default naming convention. | `string` | `null` | no |
| <a name="input_inactivity_minutes_before_sleep"></a> [inactivity\_minutes\_before\_sleep](#input\_inactivity\_minutes\_before\_sleep) | Number of minutes of inactivity before the gateway goes to sleep. Must be between 30 and 1440. | `number` | `30` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number for the gateway. | `number` | `1` | no |
| <a name="input_number_of_member_gateways"></a> [number\_of\_member\_gateways](#input\_number\_of\_member\_gateways) | Number of member gateways. Must be between 1 and 7. | `number` | `1` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout settings for the Fabric Virtual Network Gateway resource. | <pre>object({<br>    create = optional(string, "30m")<br>    read   = optional(string, "5m")<br>    update = optional(string, "30m")<br>    delete = optional(string, "30m")<br>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gateway"></a> [gateway](#output\_gateway) | n/a |
| <a name="output_gateway_id"></a> [gateway\_id](#output\_gateway\_id) | n/a |
<!-- END_TF_DOCS -->
