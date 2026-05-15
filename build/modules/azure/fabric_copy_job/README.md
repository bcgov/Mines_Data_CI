# fabric_copy_job module

Creates an **on-demand** Microsoft Fabric Copy Job that moves data from
a source (PostgreSQL / Oracle / etc.) to a Fabric Warehouse sink.

## Usage

```hcl
module "mds_copy" {
  source = "./modules/fabric_copy_job"

  workspace_id = var.fabric_workspace_id
  display_name = "mds-pg-to-warehouse"

  source_type          = "PostgreSQL"
  source_connection_id = module.postgres_connection.connection_id
  source_database      = "mds"
  source_schema        = "public"

  sink_workspace_id = var.fabric_workspace_id
  sink_warehouse_id = var.fabric_warehouse_id
  sink_schema       = "bronze"

  table_mappings = [
    { source_table = "mines",   sink_table = "mines" },
    { source_table = "permits", sink_table = "permits" },
  ]
}
```

## Running the job

This module creates the job definition only — no schedule is attached.
Trigger it via one of:

**Fabric Portal** — open the Copy Job, click *Run now*.

**Fabric CLI**
```bash
fab job run -w <workspace_id> -i <copy_job_id>
```

**REST API**
```bash
curl -X POST \
  -H "Authorization: Bearer $FABRIC_TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/<workspace_id>/items/<copy_job_id>/jobs/instances?jobType=CopyJob"
```

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `workspace_id` | Target Fabric workspace | string | — |
| `display_name` | Display name | string | — |
| `description` | Description | string | `On-demand Copy Job to Fabric Warehouse` |
| `source_type` | `PostgreSQL` or `Oracle` | string | — |
| `source_connection_id` | Fabric connection GUID | string | — |
| `source_database` | Source database name | string | — |
| `source_schema` | Source schema | string | `public` |
| `sink_workspace_id` | Sink workspace | string | — |
| `sink_warehouse_id` | Sink warehouse ID | string | — |
| `sink_schema` | Sink schema | string | `bronze` |
| `table_mappings` | `[{source_table, sink_table}]` | list(object) | — |

## Outputs

| Name | Description |
|---|---|
| `copy_job_id` | GUID of the Copy Job |
| `copy_job_display_name` | Display name |
| `run_command` | Ready-to-paste `fab job run` command |
