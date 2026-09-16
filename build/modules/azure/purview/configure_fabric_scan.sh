#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Called by null_resource.fabric_scan (apply and destroy).
#
# Registers the Fabric tenant as a Purview data source, creates a managed
# identity scan, sets its schedule, and optionally scopes it to specific
# workspaces. There is no Terraform provider for the Purview scanning data
# plane, so this drives the REST API directly.
#
# Reads:
#   ACTION      — apply | destroy
#   SCAN_CONFIG — JSON blob rendered by the module (see locals.scan_config)
#   ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID from the runner env
#
# All requests are idempotent PUTs, so re-running is safe.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ACTION="${ACTION:-apply}"

if [ -z "${SCAN_CONFIG:-}" ]; then
  echo "ERROR: SCAN_CONFIG is not set" >&2
  exit 1
fi

ENDPOINT=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['endpoint'])")
DATASOURCE=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['datasource_name'])")
SCAN=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['scan_name'])")
API_VERSION=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['api_version'])")

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

TOKEN=$(az account get-access-token \
  --resource https://purview.azure.net \
  --query accessToken -o tsv)

# call <METHOD> <URL> [BODY] — prints the response, fails on a 4xx/5xx
call() {
  local method="$1" url="$2" body="${3:-}"
  local response status payload

  if [ -n "$body" ]; then
    response=$(curl -sS -w '\n%{http_code}' -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$body" \
      "$url")
  else
    response=$(curl -sS -w '\n%{http_code}' -X "$method" \
      -H "Authorization: Bearer $TOKEN" \
      "$url")
  fi

  status=$(printf '%s' "$response" | tail -n 1)
  payload=$(printf '%s' "$response" | sed '$d')

  case "$status" in
    2*) printf '%s' "$payload"; return 0 ;;
    404) printf '%s' "$payload"; return 44 ;;
    *)
      echo "ERROR: $method $url returned $status" >&2
      echo "$payload" >&2
      return 1
      ;;
  esac
}

# ── Destroy: remove the scan, then the data source ───────────────────────────
if [ "$ACTION" = "destroy" ]; then
  echo "Deleting scan $SCAN"
  call DELETE "$ENDPOINT/scan/datasources/$DATASOURCE/scans/$SCAN?api-version=$API_VERSION" >/dev/null || true

  echo "Deleting data source $DATASOURCE"
  call DELETE "$ENDPOINT/scan/datasources/$DATASOURCE?api-version=$API_VERSION" >/dev/null || true

  echo "Done"
  exit 0
fi

# ── Apply ────────────────────────────────────────────────────────────────────

# Bodies are built in python so the config JSON is never re-quoted through the
# shell.
DATASOURCE_BODY=$(printf '%s' "$SCAN_CONFIG" | python3 -c "
import sys, json
cfg = json.load(sys.stdin)
print(json.dumps({
    'kind': 'PowerBI',
    'name': cfg['datasource_name'],
    'properties': {
        'tenant': cfg['tenant_id'],
        'collection': {
            'referenceName': cfg['collection_name'],
            'type': 'CollectionReference',
        },
    },
}))
")

SCAN_BODY=$(printf '%s' "$SCAN_CONFIG" | python3 -c "
import sys, json
cfg = json.load(sys.stdin)
props = {
    'collection': {
        'referenceName': cfg['collection_name'],
        'type': 'CollectionReference',
    },
    'connectedVia': None,
    'includePersonalWorkspaces': cfg['include_personal_workspaces'],
}
print(json.dumps({
    'kind': 'PowerBIMsi',
    'name': cfg['scan_name'],
    'dataSourceName': cfg['datasource_name'],
    'properties': props,
}))
")

TRIGGER_BODY=$(printf '%s' "$SCAN_CONFIG" | python3 -c "
import sys, json
cfg = json.load(sys.stdin)
r = cfg['recurrence']
schedule = {'hours': r['hours'], 'minutes': r['minutes']}
if r['frequency'] == 'Week':
    schedule['weekDays'] = r['week_days']
print(json.dumps({
    'properties': {
        'recurrence': {
            'frequency': r['frequency'],
            'interval': r['interval'],
            'startTime': r['start_time'],
            'timezone': r['timezone'],
            'schedule': schedule,
        },
        'scanLevel': cfg['scan_level'],
    },
}))
")

FILTER_BODY=$(printf '%s' "$SCAN_CONFIG" | python3 -c "
import sys, json
cfg = json.load(sys.stdin)
print(json.dumps({
    'properties': {
        'includeUriPrefixes': cfg['include_uri_prefixes'],
        'excludeUriPrefixes': [],
    },
}))
")

echo "Registering Fabric data source $DATASOURCE"
call PUT "$ENDPOINT/scan/datasources/$DATASOURCE?api-version=$API_VERSION" "$DATASOURCE_BODY" >/dev/null

echo "Configuring scan $SCAN"
call PUT "$ENDPOINT/scan/datasources/$DATASOURCE/scans/$SCAN?api-version=$API_VERSION" "$SCAN_BODY" >/dev/null

SCOPED=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(len(json.load(sys.stdin)['include_uri_prefixes']))")
if [ "$SCOPED" -gt 0 ]; then
  echo "Scoping scan to $SCOPED workspace(s)"
  call PUT "$ENDPOINT/scan/datasources/$DATASOURCE/scans/$SCAN/filters/custom?api-version=$API_VERSION" "$FILTER_BODY" >/dev/null
fi

echo "Setting scan schedule"
call PUT "$ENDPOINT/scan/datasources/$DATASOURCE/scans/$SCAN/triggers/default?api-version=$API_VERSION" "$TRIGGER_BODY" >/dev/null

RUN_ON_APPLY=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(str(json.load(sys.stdin)['run_on_apply']).lower())")
if [ "$RUN_ON_APPLY" = "true" ]; then
  RUN_ID=$(cat /proc/sys/kernel/random/uuid)
  SCAN_LEVEL=$(printf '%s' "$SCAN_CONFIG" | python3 -c "import sys,json; print(json.load(sys.stdin)['scan_level'])")
  echo "Starting scan run $RUN_ID"
  call POST "$ENDPOINT/scan/datasources/$DATASOURCE/scans/$SCAN:run?runId=$RUN_ID&scanLevel=$SCAN_LEVEL&api-version=$API_VERSION" >/dev/null
fi

echo "Done"
