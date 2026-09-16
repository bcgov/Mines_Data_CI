#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Destroy-time cleanup: disable the schedule, then attempt to remove it.
#
# Disable always succeeds and is what actually stops the trigger firing.
# Delete is best-effort — the module's destroy provisioner uses
# on_failure = continue so a terraform destroy is never blocked here.
# ─────────────────────────────────────────────────────────────────────────────
set -uo pipefail

: "${WORKSPACE_ID:?WORKSPACE_ID is required}"
: "${ITEM_ID:?ITEM_ID is required}"
: "${JOB_TYPE:?JOB_TYPE is required}"

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

TOKEN=$(az account get-access-token \
  --resource https://api.fabric.microsoft.com \
  --query accessToken -o tsv)

BASE="https://api.fabric.microsoft.com/v1/workspaces/${WORKSPACE_ID}/items/${ITEM_ID}/jobs/${JOB_TYPE}/schedules"

LIST=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE")

read -r SCHEDULE_ID CONFIG <<< "$(python3 -c "
import sys, json
try:
    data = json.loads(sys.argv[1])
except Exception:
    print(' '); sys.exit(0)
values = data.get('value', []) or []
if not values:
    print(' '); sys.exit(0)
s = values[0]
print(s['id'], json.dumps(s.get('configuration', {})))
" "$LIST")"

if [ -z "${SCHEDULE_ID// /}" ]; then
  echo "[schedule] nothing to remove for item ${ITEM_ID}"
  exit 0
fi

# Disable — this is what stops the trigger.
curl -s -o /dev/null -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"enabled\":false,\"configuration\":${CONFIG}}" \
  "${BASE}/${SCHEDULE_ID}"
echo "[schedule] disabled ${SCHEDULE_ID}"

# Remove — best effort.
STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X DELETE \
  -H "Authorization: Bearer $TOKEN" \
  "${BASE}/${SCHEDULE_ID}")

if [ "$STATUS" -ge 400 ]; then
  echo "[schedule] delete returned HTTP ${STATUS}; schedule left disabled"
else
  echo "[schedule] deleted ${SCHEDULE_ID}"
fi
exit 0
