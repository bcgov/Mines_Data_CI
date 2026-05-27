#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Called by terraform external data source.
# Reads display_name from stdin (JSON), returns {"id": "<uuid>"} on stdout.
# Uses ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID from environment.
# ─────────────────────────────────────────────────────────────────────────────
set -e

DISPLAY_NAME=$(python3 -c "import sys,json; print(json.load(sys.stdin)['display_name'])")

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
  "https://api.fabric.microsoft.com/v1/connections")

# Pass DISPLAY_NAME as argument so it can't conflict with shell expansion
python3 -c "
import sys, json
display_name = sys.argv[1]
data = json.loads(sys.argv[2])
match = [c for c in data.get('value', []) if c.get('displayName') == display_name]
cid = match[0]['id'] if match else ''
print(json.dumps({'id': cid}))
" "$DISPLAY_NAME" "$LIST_BODY"
