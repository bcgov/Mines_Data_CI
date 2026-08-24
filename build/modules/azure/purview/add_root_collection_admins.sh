#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Called by null_resource.root_collection_admins.
#
# Grants Root Collection Admin to each object ID by POSTing
# addRootCollectionAdmin on the Purview account.
#
# Why a script rather than one azapi_resource_action per admin: each call
# rewrites the root collection's metadata policy under optimistic concurrency.
# Terraform runs for_each instances in parallel, so several calls read the same
# entity tag and all but one fail with:
#
#   400 / 1002 — The payload is invalid.
#                Error: The entity Etag did not match in artifact store.
#
# The calls are therefore made one at a time, with a retry on the etag
# collision and on the transient statuses the policy store returns while a
# freshly created account is still initialising.
#
# Reads:
#   ACCOUNT_ID   — ARM resource ID of the Purview account
#   ADMINS       — JSON array of Entra object IDs
#   API_VERSION  — control-plane API version
#   MAX_ATTEMPTS — attempts per admin
#   RETRY_DELAY  — seconds before the first retry, doubling each attempt
#   ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_TENANT_ID from the runner env
#
# Adding a principal that is already an admin is a no-op, so re-running is safe.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

: "${ACCOUNT_ID:?ACCOUNT_ID is not set}"
: "${ADMINS:?ADMINS is not set}"
API_VERSION="${API_VERSION:-2021-12-01}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-6}"
RETRY_DELAY="${RETRY_DELAY:-10}"
SETTLE_SECONDS="${SETTLE_SECONDS:-5}"

az login --service-principal \
  --username "$ARM_CLIENT_ID" \
  --password "$ARM_CLIENT_SECRET" \
  --tenant "$ARM_TENANT_ID" \
  --output none 2>/dev/null

TOKEN=$(az account get-access-token \
  --resource https://management.azure.com \
  --query accessToken -o tsv)

URL="https://management.azure.com${ACCOUNT_ID}/addRootCollectionAdmin?api-version=${API_VERSION}"

# Retryable: the etag collision above, plus the statuses the service returns
# while the root collection policy is still being written or is under load.
is_retryable() {
  local status="$1" payload="$2"
  case "$status" in
    409|429|500|502|503|504) return 0 ;;
    400)
      # Only the etag collision — a genuinely malformed payload must fail fast.
      printf '%s' "$payload" | grep -qi 'etag did not match' && return 0
      return 1
      ;;
    *) return 1 ;;
  esac
}

grant() {
  local object_id="$1"
  local attempt=1 delay="$RETRY_DELAY"
  local response status payload

  while :; do
    response=$(curl -sS -w '\n%{http_code}' -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"objectId\":\"${object_id}\"}" \
      "$URL")

    status=$(printf '%s' "$response" | tail -n 1)
    payload=$(printf '%s' "$response" | sed '$d')

    case "$status" in
      2*)
        echo "  granted"
        return 0
        ;;
    esac

    # Already an admin — treat as success rather than an error.
    if printf '%s' "$payload" | grep -qi 'already'; then
      echo "  already an admin — skipping"
      return 0
    fi

    if is_retryable "$status" "$payload" && [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
      echo "  attempt $attempt/$MAX_ATTEMPTS returned $status — retrying in ${delay}s"
      sleep "$delay"
      attempt=$((attempt + 1))
      delay=$((delay * 2))
      continue
    fi

    echo "ERROR: granting Root Collection Admin to $object_id failed with $status" >&2
    echo "$payload" >&2
    if [ "$status" = "403" ]; then
      echo "The deploying principal needs Microsoft.Purview/accounts/addRootCollectionAdmin/action on the account (carried by Owner and Contributor)." >&2
    fi
    return 1
  done
}

mapfile -t IDS < <(printf '%s' "$ADMINS" | python3 -c "
import sys, json
for object_id in json.load(sys.stdin):
    print(object_id)
")

echo "Granting Root Collection Admin on ${ACCOUNT_ID##*/} to ${#IDS[@]} principal(s)"

first=1
for object_id in "${IDS[@]}"; do
  # Space the calls out so each one reads the policy the previous write left.
  [ "$first" -eq 1 ] || sleep "$SETTLE_SECONDS"
  first=0
  echo "$object_id"
  grant "$object_id"
done

echo "Done"
