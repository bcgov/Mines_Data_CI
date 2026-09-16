#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Create or update the schedule for a Fabric item.
#
# Idempotent: lists existing schedules for the item + job type first.
#   found    → PATCH that schedule in place
#   not found → POST a new one
# so repeated applies never stack duplicate triggers on the same item.
#
# Environment (set by the Terraform local-exec):
#   WORKSPACE_ID, ITEM_ID, JOB_TYPE, SCHEDULE_PAYLOAD, SCHEDULE_LABEL
# Credentials come from the runner environment, same as the other modules:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

: "${WORKSPACE_ID:?WORKSPACE_ID is required}"
: "${ITEM_ID:?ITEM_ID is required}"
: "${JOB_TYPE:?JOB_TYPE is required}"
: "${SCHEDULE_PAYLOAD:?SCHEDULE_PAYLOAD is required}"
LABEL="${SCHEDULE_LABEL:-$ITEM_ID}"

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

TOKEN=$(az account get-access-token \
  --resource https://api.fabric.microsoft.com \
  --query accessToken -o tsv)

BASE="https://api.fabric.microsoft.com/v1/workspaces/${WORKSPACE_ID}/items/${ITEM_ID}/jobs/${JOB_TYPE}/schedules"

# ── Look for an existing schedule ────────────────────────────────────────────
LIST=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE")

EXISTING_ID=$(python3 -c "
import sys, json
try:
    data = json.loads(sys.argv[1])
except Exception:
    print(''); sys.exit(0)
values = data.get('value', []) or []
print(values[0]['id'] if values else '')
" "$LIST")

# ── Upsert ───────────────────────────────────────────────────────────────────
if [ -n "$EXISTING_ID" ]; then
  echo "[schedule] ${LABEL}: updating existing schedule ${EXISTING_ID}"
  METHOD="PATCH"
  URL="${BASE}/${EXISTING_ID}"
else
  echo "[schedule] ${LABEL}: no schedule found, creating one"
  METHOD="POST"
  URL="$BASE"
fi

RESPONSE=$(curl -s -w $'\n%{http_code}' -X "$METHOD" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$SCHEDULE_PAYLOAD" \
  "$URL")

STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" -ge 400 ]; then
  echo "[schedule] ${LABEL}: ${METHOD} failed with HTTP ${STATUS}" >&2
  echo "$BODY" >&2
  exit 1
fi

python3 -c "
import sys, json
try:
    data = json.loads(sys.argv[1])
except Exception:
    print('[schedule] ${LABEL}: applied (no JSON body returned)'); sys.exit(0)
cfg = data.get('configuration', {}) or {}
print('[schedule] ${LABEL}: {} — {} at {} ({})'.format(
    data.get('id', 'unknown'),
    'enabled' if data.get('enabled') else 'disabled',
    ', '.join(cfg.get('times', []) or []),
    cfg.get('localTimeZoneId', 'unknown time zone'),
))
" "$BODY"
