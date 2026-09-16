# fabric_item_schedule

Recurring trigger for a Fabric item (Data Pipeline, notebook, …) via the Job
Scheduler REST API. The `microsoft/fabric` provider has no schedule resource
yet ([issue #179]), so this module wraps the API the same way
`fabric_connection` does.

## Usage

```hcl
module "schedule_pipeline_mds" {
  source = "../modules/azure/fabric_item_schedule"

  workspace_id = module.fabric_workspace_01.workspace_id
  item_id      = module.pipeline_raw_to_bronze.pipeline_id
  job_type     = "Pipeline"
  label        = "pl_ingest_mds"

  times              = ["08:00", "17:00"]
  local_time_zone_id = "Pacific Standard Time"
  enabled            = true
}
```

## Idempotency

`upsert_schedule.sh` lists the item's schedules before writing:

| State              | Action                       |
| ------------------ | ---------------------------- |
| no schedule exists | `POST` — create              |
| schedule exists    | `PATCH` — update in place    |

Re-applying never stacks duplicate triggers. The `null_resource` re-runs only
when `times`, `enabled`, the time zone, or the date window change, because
`triggers.payload_hash` is a hash of the request body.

This module assumes it is the **only** owner of schedules on the item: it
adopts the first schedule the API returns. If someone adds a second schedule
by hand in the portal, Terraform will not see or manage it.

## Time zones

`local_time_zone_id` takes a **Windows** time zone ID, not an IANA name.
Use `Pacific Standard Time` (not `America/Vancouver`) — it observes daylight
saving automatically, so 08:00 stays 08:00 local through the PST ↔ PDT switch.

## Parameters at run time

The Fabric scheduler cannot pass pipeline parameters, so scheduled runs use the
pipeline's **default** parameter values. For these ingest pipelines that means
`override_from_date` / `override_to_date` stay empty and the run is a normal
incremental load off the stored watermark.

One consequence: `triggered_by` also takes its default (`manual`), so
`app.pipeline_log` will record scheduled runs as `manual`. If most runs will be
scheduled, set `triggered_by_default = "schedule"` on the pipeline module to
make the logs read correctly, at the cost of portal-triggered runs also
reporting `schedule`.

## Requirements

- `az`, `curl`, `python3` on the runner
- `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` in the environment
- The SP needs Contributor (or higher) on the workspace. Create and Update
  Item Schedule both support service principal identities.

[issue #179]: https://github.com/microsoft/terraform-provider-fabric/issues/179
