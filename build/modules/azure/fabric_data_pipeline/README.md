# fabric_data_pipeline module

Creates a Microsoft Fabric **Data Pipeline** with one Copy activity per
table mapping. Source is a PostgreSQL connection referenced by connection ID.
Sink is a Fabric Warehouse.

Uses the confirmed-working ADF-style Copy activity schema with
`PostgreSqlSource` and `WarehouseSink` — the same schema shown in the
official Microsoft Fabric documentation examples.

## Usage

```hcl
module "pipeline_mds_to_bronze" {
  source = "./modules/fabric_data_pipeline"

  providers = {
    fabric.auth = fabric.auth
  }

  workspace_id         = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  display_name         = "pl-mds-core-to-bronze"
  source_connection_id = "21b383a1-c561-4540-980d-ce3683e89236"
  source_database      = "mds"
  source_schema        = "public"

  sink_workspace_id    = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  sink_warehouse_id    = "9ed9a608-33e5-408b-bd51-adc2dad1e7ab"
  sink_schema          = "bronze"

  table_option         = "autoCreate"
  write_behavior       = "insert"

  table_mappings = [
    { source_table = "etl_permit",  sink_table = "etl_permit"  },
    { source_table = "camp_detail", sink_table = "camp_detail" },
  ]
}
```

## Running the pipeline

Trigger it via the Fabric Portal (Run) or via REST API:

```bash
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)

curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/<workspace_id>/items/<pipeline_id>/jobs/instances?jobType=Pipeline"
```

Or use the `run_rest_command` Terraform output directly:
```bash
TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
eval $(terraform output -raw run_rest_command)
```

## On-premises sources

If your PostgreSQL is behind a private endpoint or on-prem, set:

```hcl
enable_staging = true
```

You'll also need an external Azure Storage staging account configured in
the pipeline. Staging is required by Fabric when copying from on-premises
connections to a Warehouse sink — workspace-internal staging is not supported.

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `workspace_id` | Target workspace | string | — |
| `display_name` | Pipeline display name | string | — |
| `description` | Pipeline description | string | `On-demand Data Pipeline: PostgreSQL → Fabric Warehouse` |
| `source_connection_id` | Fabric connection GUID | string | — |
| `source_database` | PostgreSQL database | string | — |
| `source_schema` | PostgreSQL schema | string | `public` |
| `sink_workspace_id` | Sink workspace | string | — |
| `sink_warehouse_id` | Sink warehouse ID | string | — |
| `sink_schema` | Sink schema | string | `bronze` |
| `table_mappings` | `[{source_table, sink_table}]` | list(object) | — |
| `write_behavior` | `insert` or `upsert` | string | `insert` |
| `table_option` | `autoCreate` or `none` | string | `autoCreate` |
| `allow_data_truncation` | Allow truncation on type mismatch | bool | `true` |
| `enable_staging` | Enable staging for on-prem sources | bool | `false` |
| `activity_timeout` | Timeout per activity | string | `0.12:00:00` |
| `activity_retry` | Retry count per activity | number | `0` |

## Outputs

| Name | Description |
|---|---|
| `pipeline_id` | GUID of the Data Pipeline |
| `pipeline_display_name` | Display name |
| `run_rest_command` | Ready-to-use REST API trigger command |
