{
  "name": "pl_bronze_to_gold",
  "properties": {
    "description": "Bronze -> silver -> gold -> model refresh. Started by the Activator trigger when pl_ingest_mds succeeds.",
    "activities": [
      {
        "name": "Bronze_Load",
        "type": "TridentNotebook",
        "description": "Raw parquet (pl_ingest_mds / pl_ingest_mto) -> bronze delta tables",
        "dependsOn": [],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "typeProperties": {
          "notebookId": "{{.nb_bronze_load}}",
          "workspaceId": "{{.workspace_id}}"
        }
      },
      {
        "name": "Silver_Registry",
        "type": "TridentNotebook",
        "description": "Rebuild app.object_registry from app.pipeline_control",
        "dependsOn": [
          {
            "activity": "Bronze_Load",
            "dependencyConditions": [
              "Succeeded"
            ]
          }
        ],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "typeProperties": {
          "notebookId": "{{.nb_silver_registry}}",
          "workspaceId": "{{.workspace_id}}"
        }
      },
      {
        "name": "Silver_Build",
        "type": "TridentNotebook",
        "description": "Bronze -> silver (dedupe, types, primary keys)",
        "dependsOn": [
          {
            "activity": "Silver_Registry",
            "dependencyConditions": [
              "Succeeded"
            ]
          }
        ],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "typeProperties": {
          "notebookId": "{{.nb_silver_build}}",
          "workspaceId": "{{.workspace_id}}"
        }
      },
      {
        "name": "Gold_Build",
        "type": "TridentNotebook",
        "description": "Silver -> all gold dims and facts (plan in nb_gold_config)",
        "dependsOn": [
          {
            "activity": "Silver_Build",
            "dependencyConditions": [
              "Succeeded"
            ]
          }
        ],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "typeProperties": {
          "notebookId": "{{.nb_gold_orchestrator}}",
          "workspaceId": "{{.workspace_id}}"
        }
      },
      {
        "name": "Refresh_Models",
        "type": "TridentNotebook",
        "description": "Full refresh of the Gold semantic models",
        "dependsOn": [
          {
            "activity": "Gold_Build",
            "dependencyConditions": [
              "Succeeded"
            ]
          }
        ],
        "policy": {
          "timeout": "0.12:00:00",
          "retry": 0,
          "retryIntervalInSeconds": 30,
          "secureOutput": false,
          "secureInput": false
        },
        "typeProperties": {
          "notebookId": "{{.nb_refresh_gold_models}}",
          "workspaceId": "{{.workspace_id}}"
        }
      }
    ],
    "concurrency": 1,
    "annotations": []
  }
}
