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

import os
import sys

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

    if os.environ.get("UNPUBLISH_ORPHANS", "false").lower() == "true":
        print("Unpublishing orphan items")
        unpublish_all_orphan_items(workspace)
    else:
        print("Skipping orphan cleanup (UNPUBLISH_ORPHANS is not 'true')")

    print("Done.")


if __name__ == "__main__":
    main()
