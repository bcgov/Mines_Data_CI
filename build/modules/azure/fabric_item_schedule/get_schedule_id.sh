#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Called by the terraform external data source.
# Reads {"workspace_id","item_id","job_type"} from stdin (JSON),
# returns {"id": "<uuid>"} on stdout (empty string when none exists).
# Uses ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID from environment.
# ─────────────────────────────────────────────────────────────────────────────
set -e

QUERY=$(cat)

WORKSPACE_ID=$(python3 -c "import sys,json; print(json.loads(sys.argv[1])['workspace_id'])" "$QUERY")
ITEM_ID=$(python3 -c "import sys,json; print(json.loads(sys.argv[1])['item_id'])" "$QUERY")
JOB_TYPE=$(python3 -c "import sys,json; print(json.loads(sys.argv[1])['job_type'])" "$QUERY")

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

TOKEN=$(az account get-access-token \
  --resource https://api.fabric.microsoft.com \
  --query accessToken -o tsv)

LIST_BODY=$(curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "https://api.fabric.microsoft.com/v1/workspaces/${WORKSPACE_ID}/items/${ITEM_ID}/jobs/${JOB_TYPE}/schedules")

# External data sources must emit a flat string map on stdout and nothing else.
python3 -c "
import sys, json
try:
    data = json.loads(sys.argv[1])
except Exception:
    print(json.dumps({'id': ''})); sys.exit(0)
values = data.get('value', []) or []
print(json.dumps({'id': values[0]['id'] if values else ''}))
" "$LIST_BODY"
