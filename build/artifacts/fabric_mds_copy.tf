# ─────────────────────────────────────────────────────────────────────────────
# Copy Job: PostgreSQL public.camp_detail → Fabric Warehouse bronze.camp_detail
#
# Uses an existing Fabric connection (351f4f16-...) — no fabric_connection
# module call needed since the connection already exists in the portal.
# ─────────────────────────────────────────────────────────────────────────────



# provider "fabric" {
#   preview = true   # fabric_copy_job is GA but other resources in the chain may be in preview
# }

module "copy_camp_detail" {
  source = "../modules/azure/fabric_copy_job"
 providers = {
    fabric.auth = fabric.auth
  }
  # ─── Target workspace (where the Copy Job item lives) ────────────────────
  workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  display_name = "copy-camp-detail-to-bronze"
  description  = "On-demand copy: PostgreSQL public.camp_detail → Fabric Warehouse mines-data-platform-fabwh1.bronze.camp_detail"

  # ─── Source: existing PostgreSQL connection ──────────────────────────────
  source_type          = "PostgreSQL"
  source_connection_id = "351f4f16-0e5d-48f8-a05a-e0a6849f0343"
  source_database      = "mds"          # adjust if the DB name on this connection is different
  source_schema        = "public"

  # ─── Sink: Fabric Warehouse mines-data-platform-fabwh1 ───────────────────
  sink_workspace_id = "8f380f88-5ce5-48d1-9fa5-fbbfbe2685a0"
  sink_warehouse_id = "9ed9a608-33e5-408b-bd51-adc2dad1e7ab"
  sink_schema       = "bronze"

  # ─── Tables to copy ──────────────────────────────────────────────────────
  table_mappings = [
    { source_table = "camp_detail", sink_table = "camp_detail" },
  ]
}

output "copy_job_id" {
  value = module.copy_camp_detail.copy_job_id
}

output "run_command" {
  description = "Run this in your shell after Terraform apply to trigger the job."
  value       = module.copy_camp_detail.run_command
}
