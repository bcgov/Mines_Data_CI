#!/bin/bash
# =============================================================================
# src/init/warehouse_init.sh
# Deploys the full SQL layer into a Fabric Warehouse, in order:
#   1. src/init/warehouse_init.sql   — schemas + tables (IF NOT EXISTS / ALTER guards)
#   2. src/procs/*.sql               — stored procedures (CREATE OR ALTER)
#   3. src/security/*.sql            — permissions (GRANTs are re-run-safe)
#   4. src/data/*.sql                — pipeline_control config (upsert SP)
#
# Every step is idempotent — safe to re-run against an already-configured
# warehouse. Follows the same auth pattern as create_workspace.sh.
#
# Required environment:
#   WORKSPACE_ID          Fabric workspace ID
#   WAREHOUSE_ID          Fabric warehouse ID
#   AZURE_CLIENT_ID       Service principal client ID
#   AZURE_CLIENT_SECRET   Service principal secret
#   AZURE_TENANT_ID       Entra tenant ID
#
# Requires go-sqlcmd (https://github.com/microsoft/go-sqlcmd) — the modern
# sqlcmd with --authentication-method support. The AZURE_* variables above are
# picked up automatically by its ActiveDirectoryDefault credential chain.
# =============================================================================

set -euo pipefail

# ══════════════════════════════════════════════════════════════
# Colors
# ══════════════════════════════════════════════════════════════

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# ══════════════════════════════════════════════════════════════
# Configuration & Validation
# ══════════════════════════════════════════════════════════════

WORKSPACE_ID="${WORKSPACE_ID:?WORKSPACE_ID is required}"
WAREHOUSE_ID="${WAREHOUSE_ID:?WAREHOUSE_ID is required}"
CLIENT_ID="${AZURE_CLIENT_ID:?AZURE_CLIENT_ID is required}"
CLIENT_SECRET="${AZURE_CLIENT_SECRET:?AZURE_CLIENT_SECRET is required}"
TENANT_ID="${AZURE_TENANT_ID:?AZURE_TENANT_ID is required}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Which sqlcmd to use. GitHub runners preinstall the legacy ODBC sqlcmd, which
# can shadow go-sqlcmd on PATH — set SQLCMD_BIN to an explicit go-sqlcmd path
# (the CI workflow does) to bypass PATH ordering entirely.
SQLCMD_BIN="${SQLCMD_BIN:-sqlcmd}"

# Ordered deployment set: init first, then procs, then data.
# Glob expansion is sorted, so numeric prefixes (010_, 020_, ...) control order.
build_sql_file_list() {
    SQL_FILES=("${SCRIPT_DIR}/warehouse_init.sql")

    local f
    for f in "${SRC_DIR}/procs/"*.sql; do
        [[ -e "$f" ]] && SQL_FILES+=("$f")
    done
    for f in "${SRC_DIR}/security/"*.sql; do
        [[ -e "$f" ]] && SQL_FILES+=("$f")
    done
    for f in "${SRC_DIR}/data/"*.sql; do
        [[ -e "$f" ]] && SQL_FILES+=("$f")
    done
}

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║             Fabric Warehouse Initializer                          ║"
echo "║             init → procs → data  (idempotent)                     ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}[INFO]${NC} Workspace ID : ${WORKSPACE_ID}"
echo -e "${BLUE}[INFO]${NC} Warehouse ID : ${WAREHOUSE_ID}"

# ══════════════════════════════════════════════════════════════
# Validate dependencies
# ══════════════════════════════════════════════════════════════

check_dependencies() {
    local missing=()

    command -v az      &>/dev/null || missing+=("azure-cli")
    command -v curl    &>/dev/null || missing+=("curl")
    command -v jq      &>/dev/null || missing+=("jq")
    command -v "$SQLCMD_BIN" &>/dev/null || missing+=("sqlcmd (go-sqlcmd)")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}[✗]${NC} Missing required tools: ${missing[*]}"
        echo ""
        echo "Install go-sqlcmd on Linux:"
        echo "  curl -fsSL -o /tmp/sqlcmd.tar.bz2 https://github.com/microsoft/go-sqlcmd/releases/latest/download/sqlcmd-linux-amd64.tar.bz2"
        echo "  tar -xjf /tmp/sqlcmd.tar.bz2 -C /tmp sqlcmd"
        echo "  sudo mv /tmp/sqlcmd /usr/local/bin/sqlcmd"
        exit 1
    fi

    # The legacy ODBC sqlcmd (mssql-tools18) cannot do service-principal auth
    # non-interactively on Linux and doesn't support --version (it errors),
    # while go-sqlcmd does — use that as the discriminator. GitHub runners
    # preinstall the legacy one, so a plain 'sqlcmd' on PATH may be wrong;
    # point SQLCMD_BIN at a go-sqlcmd binary explicitly in that case.
    if ! "$SQLCMD_BIN" --version &>/dev/null; then
        echo -e "${RED}[✗]${NC} '$SQLCMD_BIN' appears to be the legacy ODBC sqlcmd (or is broken)."
        echo "This script requires go-sqlcmd. Either install it first on PATH,"
        echo "or set SQLCMD_BIN=/path/to/go-sqlcmd (see install instructions above)."
        exit 1
    fi

    echo -e "${GREEN}[✓]${NC} All dependencies present (go-sqlcmd: $("$SQLCMD_BIN" --version 2>/dev/null | tr -d '\r'))"
}

# ══════════════════════════════════════════════════════════════
# Authentication — identical pattern to create_workspace.sh
# ══════════════════════════════════════════════════════════════

authenticate_azure() {
    echo -e "${BLUE}[INFO]${NC} Logging into Azure via Service Principal..."
    az login --service-principal \
        --username "$CLIENT_ID" \
        --password "$CLIENT_SECRET" \
        --tenant "$TENANT_ID" \
        --allow-no-subscriptions \
        --output none
    echo -e "${GREEN}[✓]${NC} Azure login successful"
}

get_fabric_token() {
    echo -e "${BLUE}[INFO]${NC} Fetching Fabric access token..." >&2
    az account get-access-token \
        --resource https://api.fabric.microsoft.com \
        --query accessToken \
        -o tsv
}

# ══════════════════════════════════════════════════════════════
# Resolve warehouse connection string + name via Fabric REST API
# ══════════════════════════════════════════════════════════════

resolve_warehouse() {
    local token="$1"

    echo -e "${BLUE}[INFO]${NC} Resolving warehouse connection details..." >&2

    local response
    response=$(curl -s \
        -H "Authorization: Bearer ${token}" \
        "https://api.fabric.microsoft.com/v1/workspaces/${WORKSPACE_ID}/warehouses/${WAREHOUSE_ID}")

    WH_SERVER=$(echo "$response" | jq -r '.properties.connectionString // empty')
    WH_DATABASE=$(echo "$response" | jq -r '.displayName // empty')

    if [[ -z "$WH_SERVER" || -z "$WH_DATABASE" ]]; then
        echo -e "${RED}[✗]${NC} Could not resolve warehouse. Response:" >&2
        echo "$response" >&2
        exit 1
    fi

    echo -e "${GREEN}[✓]${NC} SQL endpoint : ${WH_SERVER}" >&2
    echo -e "${GREEN}[✓]${NC} Database     : ${WH_DATABASE}" >&2
}

# ══════════════════════════════════════════════════════════════
# Execute SQL files in order
# ══════════════════════════════════════════════════════════════

run_sql_file() {
    local sql_file="$1"

    if [[ ! -f "$sql_file" ]]; then
        echo -e "${RED}[✗]${NC} SQL file not found: ${sql_file}"
        exit 1
    fi

    echo ""
    echo -e "${BOLD}Running $(basename "$sql_file")...${NC}"
    echo "─────────────────────────────────────────────────────────────────"

    # ActiveDirectoryDefault picks up AZURE_CLIENT_ID / AZURE_CLIENT_SECRET /
    # AZURE_TENANT_ID from the environment (service-principal credential),
    # falling back to the az CLI login above when run locally.
    # -C  = trust server certificate
    # -b  = exit on first error
    # -i  = input file
    "$SQLCMD_BIN" \
        -S "$WH_SERVER" \
        -d "$WH_DATABASE" \
        --authentication-method ActiveDirectoryDefault \
        -C \
        -b \
        -i "$sql_file"

    echo "─────────────────────────────────────────────────────────────────"
    echo -e "${GREEN}[✓]${NC} $(basename "$sql_file") executed successfully"
}

# ══════════════════════════════════════════════════════════════
# Main
# ══════════════════════════════════════════════════════════════

main() {
    check_dependencies
    authenticate_azure

    local fabric_token
    fabric_token=$(get_fabric_token)

    resolve_warehouse "$fabric_token"

    build_sql_file_list
    echo ""
    echo -e "${BLUE}[INFO]${NC} Deployment order:"
    local f
    for f in "${SQL_FILES[@]}"; do
        echo "         - ${f#"${SRC_DIR}/../"}"
    done

    for f in "${SQL_FILES[@]}"; do
        run_sql_file "$f"
    done

    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Warehouse deployment complete!                              ${NC}"
    echo -e "${GREEN}${BOLD}  Schemas:  bronze | silver | gold | app                      ${NC}"
    echo -e "${GREEN}${BOLD}  Objects:  pipeline_control | pipeline_log | config          ${NC}"
    echo -e "${GREEN}${BOLD}            error_log | schema_registry                       ${NC}"
    echo -e "${GREEN}${BOLD}  Procs:    usp_upsert_pipeline_control | usp_pipeline_log    ${NC}"
    echo -e "${GREEN}${BOLD}  Data:     pipeline_control config upserted                  ${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════════════${NC}"
}

main "$@"