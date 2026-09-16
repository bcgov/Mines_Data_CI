# ─────────────────────────────────────────────────────────────────────────────
# fabric-cicd parameter file — TEMPLATE
#
# Rendered to fabric/items/parameter.yml by .github/workflows/fabric.yml with
# values read out of build/artifacts/terraform-<env>.tfstate. Never commit the
# rendered file: add fabric/items/parameter.yml to .gitignore.
#
# The find_value entries are the DEV identifiers that are baked into the item
# definitions in git (they are whatever the DEV workspace happened to hand out
# when the items were authored). Re-run `git grep` for them if items are ever
# re-synced from a different workspace — if a find_value goes stale, the
# replacement silently does nothing and TEST/PROD items point at DEV data.
#
# When deploying to dev these replacements are identity no-ops by design, so
# the same path runs for every environment.
# ─────────────────────────────────────────────────────────────────────────────


find_replace:

  # ── Workspace GUID ─────────────────────────────────────────────────────────
  # notebook-content.py METADATA (default_lakehouse_workspace_id) and the
  # OneLake DataLake URLs in the NoW semantic models. 18 files.
  - find_value: "475a3e70-610e-49ae-be54-dd2c31167535"
    replace_value:
      ${ENV_KEY}: "${WORKSPACE_ID}"

  # ── Lakehouse GUID ─────────────────────────────────────────────────────────
  # notebook default_lakehouse / known_lakehouses, OneLake paths. 18 files.
  - find_value: "896cd6b0-6cd0-47e5-8438-f50dde9564b8"
    replace_value:
      ${ENV_KEY}: "${LAKEHOUSE_ID}"

  # ── Lakehouse display name ─────────────────────────────────────────────────
  # notebook default_lakehouse_name + the Variable Library default value set.
  - find_value: "mcm_mdp_lh1_dev"
    replace_value:
      ${ENV_KEY}: "${LAKEHOUSE_NAME}"

  # ── Warehouse display name ─────────────────────────────────────────────────
  # Variable Library default value set (warehouse_name).
  - find_value: "mcm-mdp-fabwh1-dev"
    replace_value:
      ${ENV_KEY}: "${WAREHOUSE_NAME}"

  # ── Lakehouse SQL analytics endpoint GUID ──────────────────────────────────
  # Sql.Database(...) second argument in the Gold Incidents / Gold Inspections
  # semantic models (expressions.tmdl).
  - find_value: "9e72dd5d-ed1c-4214-a662-31e5f91defab"
    replace_value:
      ${ENV_KEY}: "${SQL_ENDPOINT_ID}"

  # ── SQL analytics endpoint host ────────────────────────────────────────────
  # Case matters: find_replace is a literal string match, and TMDL stores this
  # host upper-cased while Terraform state stores it lower-cased. Both variants
  # are listed so a re-sync in either casing is still caught.
  - find_value: "ABJNW3YNHWFEVMBW2NUF4NM23Q-OA7FURYOMGXETPSU3UWDCFTVGU.datawarehouse.fabric.microsoft.com"
    replace_value:
      ${ENV_KEY}: "${SQL_ENDPOINT_HOST_UPPER}"
  - find_value: "abjnw3ynhwfevmbw2nuf4nm23q-oa7furyomgxetpsu3uwdcftvgu.datawarehouse.fabric.microsoft.com"
    replace_value:
      ${ENV_KEY}: "${SQL_ENDPOINT_HOST_LOWER}"
