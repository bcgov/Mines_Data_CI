# ─────────────────────────────────────────────────────────────────────────────
# pl_bronze_to_gold — runs our medallion notebooks in order, then refreshes the
# Gold semantic models:
#
#   nb_bronze_load → nb_silver_registry → nb_silver_build
#     → nb_gold_orchestrator → nb_refresh_gold_models
#
# Kept separate from pl_ingest_mds / pl_ingest_mto (those only land raw data).
# It is started by a Fabric trigger on pl_ingest_mds succeeding (added as a
# separate change), so it has no schedule of its own. Run it by hand from the
# portal when needed.
#
# The notebooks are published by fabric.yml (fabric-cicd), not Terraform, so
# they are looked up here by display name. They must already exist in the
# workspace before this is applied.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  bronze_to_gold_notebooks = [
    "nb_bronze_load",
    "nb_silver_registry",
    "nb_silver_build",
    "nb_gold_orchestrator",
    "nb_refresh_gold_models",
  ]
}

data "fabric_notebook" "bronze_to_gold" {
  provider     = fabric.auth
  for_each     = toset(local.bronze_to_gold_notebooks)
  workspace_id = module.fabric_workspace_01.workspace_id
  display_name = each.value
}

resource "fabric_data_pipeline" "bronze_to_gold" {
  provider     = fabric.auth
  workspace_id = module.fabric_workspace_01.workspace_id
  folder_id    = local.fabric_item_folder_ids["pipelines"]
  display_name = "pl_bronze_to_gold"
  description  = "Bronze → silver → gold → Gold model refresh. Started when pl_ingest_mds succeeds."
  format       = "Default"

  definition_update_enabled = true

  definition = {
    "pipeline-content.json" = {
      source = "${path.module}/pl_bronze_to_gold.json.tpl"
      tokens = merge(
        { workspace_id = module.fabric_workspace_01.workspace_id },
        { for name, nb in data.fabric_notebook.bronze_to_gold : name => nb.id }
      )
    }
  }
}

output "pipeline_bronze_to_gold_id" {
  description = "pl_bronze_to_gold item ID (the trigger targets this)."
  value       = fabric_data_pipeline.bronze_to_gold.id
}
