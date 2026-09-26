# ─────────────────────────────────────────────────────────────────────────────
# pl_bronze_to_gold — runs our medallion notebooks in order, then refreshes the
# Gold semantic models:
#
#   nb_bronze_load → nb_silver_registry → nb_silver_build → nb_gold_orchestrator
#     → Semantic model refresh (one activity per Gold model, in parallel)
#
# Kept separate from pl_ingest_mds / pl_ingest_mto (those only land raw data).
#
# Model refresh uses the built-in "Semantic model refresh" activity through a
# Power BI Semantic Model connection with Workspace identity auth. A refresh
# from a notebook does not work here: the pipeline runs as the Terraform
# service principal, and the Power BI token a notebook gets for it is refused
# (403 on /groups/<ws>/datasets).
#
# That connection type cannot be created through the Fabric REST API, so it is
# created ONCE per environment in the portal (Settings → Manage connections):
#   name: semanticmodel-<PREFIX>-<PROJECT>-<ENVIRONMENT>  (e.g. semanticmodel-mcm-mdp-prod)
#   type: Power BI Semantic Model, auth: Workspace identity
#   shared with the Terraform service principal (User or Owner) so this
#   lookup can see it.
# Until it exists the pipeline is published WITHOUT the refresh activities, so
# a missing connection never blocks an apply.
#
# The notebooks are published by fabric.yml (fabric-cicd), not Terraform, so
# they are looked up by display name and must already exist.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  bronze_to_gold_notebooks = [
    { activity = "Bronze_Load", notebook = "nb_bronze_load", description = "Raw parquet (pl_ingest_mds / pl_ingest_mto) -> bronze delta tables" },
    { activity = "Silver_Registry", notebook = "nb_silver_registry", description = "Rebuild app.object_registry from app.pipeline_control" },
    { activity = "Silver_Build", notebook = "nb_silver_build", description = "Bronze -> silver (dedupe, types, primary keys)" },
    { activity = "Gold_Build", notebook = "nb_gold_orchestrator", description = "Silver -> all gold dims and facts (plan in nb_gold_config)" },
  ]

  gold_semantic_models = {
    Refresh_Incidents      = "Gold Incidents Semantic Model"
    Refresh_Inspections    = "Gold Inspections Semantic Model"
    Refresh_NoW_Permitting = "Gold NoW Permitting Semantic Model"
    Refresh_NoW_Received   = "Gold NoW Received Semantic Model"
  }

  semantic_model_connection_name = "semanticmodel-${var.PREFIX}-${var.PROJECT}-${var.ENVIRONMENT}"
  semantic_model_connection_id   = data.external.semantic_model_connection.result.id
  semantic_model_ids             = { for m in data.fabric_semantic_models.gold.values : m.display_name => m.id }

  bronze_to_gold_policy = {
    timeout                = "0.12:00:00"
    retry                  = 0
    retryIntervalInSeconds = 30
    secureOutput           = false
    secureInput            = false
  }

  bronze_to_gold_notebook_activities = [
    for i, s in local.bronze_to_gold_notebooks : {
      name        = s.activity
      type        = "TridentNotebook"
      description = s.description
      dependsOn = i == 0 ? [] : [{
        activity             = local.bronze_to_gold_notebooks[i - 1].activity
        dependencyConditions = ["Succeeded"]
      }]
      policy = local.bronze_to_gold_policy
      typeProperties = {
        notebookId  = data.fabric_notebook.bronze_to_gold[s.notebook].id
        workspaceId = module.fabric_workspace_01.workspace_id
      }
    }
  ]

  bronze_to_gold_refresh_activities = local.semantic_model_connection_id == "" ? [] : [
    for activity, model in local.gold_semantic_models : {
      name        = activity
      type        = "PBISemanticModelRefresh"
      description = "Full refresh of ${model}"
      dependsOn   = [{ activity = "Gold_Build", dependencyConditions = ["Succeeded"] }]
      policy      = local.bronze_to_gold_policy
      typeProperties = {
        method           = "post"
        waitOnCompletion = true
        commitMode       = "Transactional"
        operationType    = "SemanticModelRefresh"
        groupId          = module.fabric_workspace_01.workspace_id
        datasetId        = local.semantic_model_ids[model]
      }
      externalReferences = { connection = local.semantic_model_connection_id }
    }
  ]
}

data "fabric_notebook" "bronze_to_gold" {
  provider     = fabric.auth
  for_each     = toset([for s in local.bronze_to_gold_notebooks : s.notebook])
  workspace_id = module.fabric_workspace_01.workspace_id
  display_name = each.value
}

data "fabric_semantic_models" "gold" {
  provider     = fabric.auth
  workspace_id = module.fabric_workspace_01.workspace_id
}

# Same lookup script as modules/azure/fabric_connection: returns {"id": ""} when
# the connection is missing or not shared with the service principal.
data "external" "semantic_model_connection" {
  program = ["bash", "${path.module}/../modules/azure/fabric_connection/get_connection_id.sh"]
  query = {
    display_name = local.semantic_model_connection_name
  }
}

resource "fabric_data_pipeline" "bronze_to_gold" {
  provider     = fabric.auth
  workspace_id = module.fabric_workspace_01.workspace_id
  folder_id    = local.fabric_item_folder_ids["pipelines"]
  display_name = "pl_bronze_to_gold"
  description  = "Bronze → silver → gold → Gold model refresh. Run after pl_ingest_mds."
  format       = "Default"

  definition_update_enabled = true

  definition = {
    "pipeline-content.json" = {
      source = "${path.module}/pl_bronze_to_gold.json.tpl"
      tokens = {
        activities_json = jsonencode(concat(
          local.bronze_to_gold_notebook_activities,
          local.bronze_to_gold_refresh_activities,
        ))
      }
    }
  }
}

output "pipeline_bronze_to_gold_id" {
  description = "pl_bronze_to_gold item ID."
  value       = fabric_data_pipeline.bronze_to_gold.id
}

output "pipeline_bronze_to_gold_model_refresh" {
  description = "Whether the Gold model refresh activities are in the pipeline (needs the semanticmodel-* connection)."
  value       = local.semantic_model_connection_id == "" ? "OFF - create connection ${local.semantic_model_connection_name}" : "ON via connection ${local.semantic_model_connection_id}"
}
