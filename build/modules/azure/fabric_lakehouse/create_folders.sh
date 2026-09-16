#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Create folders under a Lakehouse's Files/ area in OneLake.
#
# OneLake exposes the ADLS Gen2 (DFS) API, so a folder is created with:
#   PUT https://onelake.dfs.fabric.microsoft.com/{ws}/{lakehouse}/Files/{path}?resource=directory
#
# Note the token audience is https://storage.azure.com — the OneLake data plane
# uses storage scopes, not the Fabric API scope used elsewhere in this repo.
#
# Idempotent: a directory that already exists comes back 409 Conflict, which is
# treated as success, so re-applying is always safe.
#
# Environment (set by the Terraform local-exec):
#   WORKSPACE_ID, LAKEHOUSE_ID, LAKEHOUSE_NAME, FOLDERS (comma separated)
# Credentials from the runner, as with the other modules:
#   ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

: "${WORKSPACE_ID:?WORKSPACE_ID is required}"
: "${LAKEHOUSE_ID:?LAKEHOUSE_ID is required}"
: "${FOLDERS:?FOLDERS is required}"
LABEL="${LAKEHOUSE_NAME:-$LAKEHOUSE_ID}"

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

# OneLake data plane uses the storage audience, not api.fabric.microsoft.com
TOKEN=$(az account get-access-token \
  --resource https://storage.azure.com \
  --query accessToken -o tsv)

BASE="https://onelake.dfs.fabric.microsoft.com/${WORKSPACE_ID}/${LAKEHOUSE_ID}/Files"

echo "[lakehouse] ${LABEL}: ensuring Files/ folders"

created=0
existed=0

# Expand "raw/bronze" into "raw" and "raw/bronze" so parents exist first, then
# de-duplicate while preserving order.
mapfile -t PATHS < <(python3 -c "
import sys
folders = [f.strip().strip('/') for f in sys.argv[1].split(',') if f.strip()]
seen, out = set(), []
for f in folders:
    parts = f.split('/')
    for i in range(1, len(parts) + 1):
        p = '/'.join(parts[:i])
        if p not in seen:
            seen.add(p)
            out.append(p)
print('\n'.join(out))
" "$FOLDERS")

for path in "${PATHS[@]}"; do
  [ -z "$path" ] && continue

  STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X PUT \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Length: 0" \
    "${BASE}/${path}?resource=directory")

  case "$STATUS" in
    201)
      echo "  created  Files/${path}"
      created=$((created + 1))
      ;;
    409)
      # PathAlreadyExists — the idempotent case
      echo "  exists   Files/${path}"
      existed=$((existed + 1))
      ;;
    403)
      echo "  ERROR    Files/${path}: 403 Forbidden" >&2
      echo "           The service principal needs write access to the workspace." >&2
      exit 1
      ;;
    *)
      echo "  ERROR    Files/${path}: HTTP ${STATUS}" >&2
      exit 1
      ;;
  esac
done

echo "[lakehouse] ${LABEL}: ${created} created, ${existed} already present"
