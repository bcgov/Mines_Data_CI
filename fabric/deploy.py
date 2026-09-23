#!/usr/bin/env python3
"""Publish the Fabric item definitions in fabric/items/ into one workspace.

Called by .github/workflows/fabric.yml. Everything environment-specific comes
in through environment variables so the script itself has no per-environment
branching:

    FABRIC_WORKSPACE_ID   target workspace GUID (from terraform-<env>.tfstate)
    FABRIC_ENVIRONMENT    DEV | TEST | PROD  — must match both the environment
                          keys in parameter.yml and the Variable Library value
                          set names, or the wrong value set stays active
    FABRIC_ITEMS_DIR      repository directory holding the .platform items
    UNPUBLISH_ORPHANS     'true' to delete workspace items absent from git
    AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET

Publishing is idempotent — items are matched on display name and updated in
place, so a re-run against an unchanged branch is a no-op.
"""

import glob
import json
import os
import sys
import time

import requests

from azure.identity import ClientSecretCredential
from fabric_cicd import (
    FabricWorkspace,
    change_log_level,
    publish_all_items,
    unpublish_all_orphan_items,
)

# Item types published from git. Lakehouse, Warehouse, and DataPipeline are
# deliberately excluded: Terraform owns those (build/artifacts/fabric_*.tf) and
# letting both tools manage them would fight over the same objects.
ITEM_TYPES = [
    "VariableLibrary",
    "Notebook",
    "SemanticModel",
    "Report",
]


# Power BI REST API — semantic model refresh. Publishing a Direct Lake model
# replaces its definition and leaves it unframed; until it is refreshed every
# report on it shows "Something's wrong with one or more fields". So every
# model this run published is refreshed straight after, and the run fails if a
# refresh fails — a blank model shows up as a red deploy, not a blank report.
PBI_API = "https://api.powerbi.com/v1.0/myorg"
PBI_SCOPE = "https://analysis.windows.net/powerbi/api/.default"
REFRESH_TIMEOUT_SECONDS = 900
REFRESH_POLL_SECONDS = 10


def published_semantic_models(repository_directory: str) -> list[str]:
    """Display names of the SemanticModel items in the repository directory."""
    names = []
    pattern = os.path.join(repository_directory, "**", ".platform")
    for platform_file in glob.glob(pattern, recursive=True):
        with open(platform_file, encoding="utf-8-sig") as f:
            metadata = json.load(f).get("metadata", {})
        if metadata.get("type") == "SemanticModel" and metadata.get("displayName"):
            names.append(metadata["displayName"])
    return sorted(names)


def refresh_semantic_models(credential, workspace_id: str, model_names: list[str]) -> None:
    """Trigger a full refresh of each model and wait for all of them to finish."""
    if not model_names:
        print("No semantic models in scope — skipping refresh")
        return

    token = credential.get_token(PBI_SCOPE).token
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(f"{PBI_API}/groups/{workspace_id}/datasets", headers=headers, timeout=60)
    response.raise_for_status()
    ids_by_name = {d["name"]: d["id"] for d in response.json().get("value", [])}

    pending = {}
    for name in model_names:
        dataset_id = ids_by_name.get(name)
        if not dataset_id:
            sys.exit(f"ERROR: published semantic model '{name}' not found in workspace {workspace_id}.")
        response = requests.post(
            f"{PBI_API}/groups/{workspace_id}/datasets/{dataset_id}/refreshes",
            headers=headers,
            json={"type": "full"},
            timeout=60,
        )
        if response.status_code not in (200, 202):
            sys.exit(f"ERROR: could not start refresh of '{name}': {response.status_code} {response.text}")
        print(f"Refresh started: {name}")
        pending[name] = dataset_id

    failed = []
    deadline = time.monotonic() + REFRESH_TIMEOUT_SECONDS
    while pending and time.monotonic() < deadline:
        time.sleep(REFRESH_POLL_SECONDS)
        for name, dataset_id in list(pending.items()):
            response = requests.get(
                f"{PBI_API}/groups/{workspace_id}/datasets/{dataset_id}/refreshes?$top=1",
                headers=headers,
                timeout=60,
            )
            response.raise_for_status()
            latest = (response.json().get("value") or [{}])[0]
            status = latest.get("status")
            if status == "Completed":
                print(f"Refresh completed: {name}")
                del pending[name]
            elif status in ("Failed", "Cancelled", "Disabled"):
                print(f"Refresh {status.lower()}: {name} — {latest.get('serviceExceptionJson', '')}")
                failed.append(name)
                del pending[name]

    if pending:
        failed.extend(f"{name} (timed out)" for name in pending)
    if failed:
        sys.exit("ERROR: semantic model refresh failed for: " + ", ".join(failed))


def require(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(f"ERROR: required environment variable {name} is not set.")
    return value


def main() -> None:
    workspace_id = require("FABRIC_WORKSPACE_ID")
    environment = require("FABRIC_ENVIRONMENT")
    items_dir = require("FABRIC_ITEMS_DIR")

    # fabric-cicd only applies parameter.yml when the repository directory is
    # an absolute path.
    repository_directory = os.path.abspath(items_dir)
    if not os.path.isdir(repository_directory):
        sys.exit(f"ERROR: items directory not found: {repository_directory}")

    parameter_file = os.path.join(repository_directory, "parameter.yml")
    if not os.path.isfile(parameter_file):
        sys.exit(
            "ERROR: parameter.yml was not rendered into "
            f"{repository_directory}. Without it, DEV GUIDs would be published "
            "unchanged and this environment's items would read DEV data."
        )

    if os.environ.get("RUNNER_DEBUG") == "1":
        change_log_level("DEBUG")

    credential = ClientSecretCredential(
        tenant_id=require("AZURE_TENANT_ID"),
        client_id=require("AZURE_CLIENT_ID"),
        client_secret=require("AZURE_CLIENT_SECRET"),
    )

    print(f"Publishing {items_dir} → workspace {workspace_id} as {environment}")

    workspace = FabricWorkspace(
        workspace_id=workspace_id,
        environment=environment,
        repository_directory=repository_directory,
        item_type_in_scope=ITEM_TYPES,
        token_credential=credential,
    )

    publish_all_items(workspace)

    refresh_semantic_models(
        credential,
        workspace_id,
        published_semantic_models(repository_directory),
    )

    if os.environ.get("UNPUBLISH_ORPHANS", "false").lower() == "true":
        print("Unpublishing orphan items")
        unpublish_all_orphan_items(workspace)
    else:
        print("Skipping orphan cleanup (UNPUBLISH_ORPHANS is not 'true')")

    print("Done.")


if __name__ == "__main__":
    main()
