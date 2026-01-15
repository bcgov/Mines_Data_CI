<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_fabric"></a> [fabric](#requirement\_fabric) | 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_fabric.auth"></a> [fabric.auth](#provider\_fabric.auth) | 1.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [fabric_workspace.this](https://registry.terraform.io/providers/microsoft/fabric/1.6.0/docs/resources/workspace) | resource |
| [fabric_workspace_role_assignment.admins](https://registry.terraform.io/providers/microsoft/fabric/1.6.0/docs/resources/workspace_role_assignment) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_id"></a> [capacity\_id](#input\_capacity\_id) | ID of the Fabric Capacity to assign to the workspace. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the Fabric Workspace. | `string` | `"Default Workspace Description"` | no |
| <a name="input_enable_git_integration"></a> [enable\_git\_integration](#input\_enable\_git\_integration) | Flag to enable Fabric Workspace Git integration. | `bool` | `false` | no |
| <a name="input_git_initialization_strategy"></a> [git\_initialization\_strategy](#input\_git\_initialization\_strategy) | The initialization strategy for Git integration. Accepted values: PreferRemote, PreferWorkspace. | `string` | `null` | no |
| <a name="input_git_provider_details"></a> [git\_provider\_details](#input\_git\_provider\_details) | Git provider details for Fabric Workspace Git integration. | <pre>object({<br>    git_provider_type = string<br>    organization_name = string<br>    project_name      = string<br>    repository_name   = string<br>    branch_name       = string<br>    directory_name    = string<br>  })</pre> | `null` | no |
| <a name="input_identity_type"></a> [identity\_type](#input\_identity\_type) | Type of identity to assign. Only SystemAssigned is allowed. Empty string disables identity. | `string` | `""` | no |
| <a name="input_instance_number"></a> [instance\_number](#input\_instance\_number) | Instance number for the workspace. | `number` | `1` | no |
| <a name="input_owners"></a> [owners](#input\_owners) | List of user principal names (emails) to grant Admin on the Fabric Workspace. | `list(string)` | `[]` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix for the workspace name. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name for the workspace. | `string` | n/a | yes |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Timeout settings for the Fabric Workspace resource. | <pre>object({<br>    create = optional(string, "30m")<br>    read   = optional(string, "5m")<br>    update = optional(string, "30m")<br>    delete = optional(string, "30m")<br>  })</pre> | `{}` | no |
| <a name="input_timeouts_git"></a> [timeouts\_git](#input\_timeouts\_git) | Timeout settings for the Fabric Workspace Git Integration resource. | <pre>object({<br>    create = optional(string)<br>    read   = optional(string)<br>    update = optional(string)<br>    delete = optional(string)<br>  })</pre> | `{}` | no |
| <a name="input_workspace_name"></a> [workspace\_name](#input\_workspace\_name) | Optional workspace name to override the default naming convention. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_workspace"></a> [workspace](#output\_workspace) | n/a |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | n/a |
<!-- END_TF_DOCS -->