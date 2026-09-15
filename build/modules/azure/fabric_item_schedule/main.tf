# ─────────────────────────────────────────────────────────────────────────────
# Fabric Item Schedule — recurring trigger for a Data Pipeline (or any Fabric
# item that exposes a job type).
#
# The microsoft/fabric provider has no schedule resource yet
# (github.com/microsoft/terraform-provider-fabric issue #179), so this module
# drives the Job Scheduler REST API:
#
#   GET    /v1/workspaces/{ws}/items/{item}/jobs/{jobType}/schedules
#   POST   /v1/workspaces/{ws}/items/{item}/jobs/{jobType}/schedules
#   PATCH  /v1/workspaces/{ws}/items/{item}/jobs/{jobType}/schedules/{id}
#
# Both POST and PATCH support service principal identities, so the CI SP that
# runs Terraform can own these schedules.
#
# Idempotent: the upsert script lists existing schedules first. If one exists
# it is PATCHed in place, otherwise a new one is created — so re-applying
# never stacks duplicate triggers on the item. The null_resource only re-runs
# when the desired configuration actually changes (triggers = payload hash).
#
# State contains: schedule ID (a GUID)
# State does NOT contain: SP credentials
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = ">= 2.0"
    }
  }
}

locals {
  # Daily schedule config. `times` are local to localTimeZoneId, in hh:mm.
  # Windows time zone IDs (e.g. "Pacific Standard Time") follow DST on their
  # own, so 08:00 stays 08:00 local through the PST → PDT switch.
  schedule_body = jsonencode({
    enabled = var.enabled

    configuration = {
      type            = "Daily"
      times           = var.times
      localTimeZoneId = var.local_time_zone_id
      startDateTime   = var.start_date_time
      endDateTime     = var.end_date_time
    }
  })
}

# ── Create or update the schedule ────────────────────────────────────────────
resource "null_resource" "schedule" {
  triggers = {
    workspace_id = var.workspace_id
    item_id      = var.item_id
    job_type     = var.job_type
    payload_hash = sha256(local.schedule_body)
  }

  provisioner "local-exec" {
    command     = "bash ${path.module}/upsert_schedule.sh"
    interpreter = ["bash", "-c"]

    environment = {
      WORKSPACE_ID      = var.workspace_id
      ITEM_ID           = var.item_id
      JOB_TYPE          = var.job_type
      SCHEDULE_PAYLOAD  = local.schedule_body
      SCHEDULE_LABEL    = var.label
    }
  }

  # On destroy: disable first (always works), then try to delete. Delete is
  # tolerated as best-effort so a destroy is never blocked by the scheduler API.
  provisioner "local-exec" {
    when        = destroy
    on_failure  = continue
    command     = "bash ${path.module}/delete_schedule.sh"
    interpreter = ["bash", "-c"]

    environment = {
      WORKSPACE_ID = self.triggers.workspace_id
      ITEM_ID      = self.triggers.item_id
      JOB_TYPE     = self.triggers.job_type
    }
  }
}

# ── Read the schedule ID back into state ─────────────────────────────────────
data "external" "schedule_id" {
  program = ["bash", "${path.module}/get_schedule_id.sh"]

  query = {
    workspace_id = var.workspace_id
    item_id      = var.item_id
    job_type     = var.job_type
  }

  depends_on = [null_resource.schedule]
}
