#!/usr/bin/env python3
"""
Export every item definition from one or more Fabric workspaces into
<ARCHIVE_DIR>/<workspace>/<item>.<Type>/..., the same on-disk layout Fabric
git integration and fabric-cicd use, so an archived item can be re-published
with fabric/deploy.py if ever needed.

Environment:
  AZURE_TENANT_ID / AZURE_CLIENT_ID / AZURE_CLIENT_SECRET   service principal
  FABRIC_WORKSPACES   workspace names or IDs, comma- or newline-separated
  ARCHIVE_DIR         output root (default: archive)

Each workspace folder is replaced wholesale on every run, so items deleted
from the workspace disappear from the archive too. A manifest.json per
workspace records what was exported, skipped (type has no definition API),
or failed.
"""
import base64
import json
import os
import re
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import requests
from azure.identity import ClientSecretCredential

API = "https://api.fabric.microsoft.com/v1"
SCOPE = "https://api.fabric.microsoft.com/.default"
GUID_RE = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
# Characters that are invalid in file names on Windows (keeps the repo cloneable everywhere)
UNSAFE_CHARS = re.compile(r'[<>:"/\\|?*\x00-\x1f]')
# Error codes meaning "this item type has no exportable definition" — skip, don't fail
UNSUPPORTED_CODES = {"OperationNotSupportedForItem", "ItemTypeNotSupported", "UnsupportedItemType"}


def gh_warning(msg: str) -> None:
    print(f"::warning::{msg}", flush=True)


def gh_error(msg: str) -> None:
    print(f"::error::{msg}", flush=True)


def safe_name(name: str) -> str:
    cleaned = UNSAFE_CHARS.sub("_", name).strip().rstrip(".")
    return cleaned or "_"


class FabricClient:
    def __init__(self) -> None:
        missing = [v for v in ("AZURE_TENANT_ID", "AZURE_CLIENT_ID", "AZURE_CLIENT_SECRET") if not os.environ.get(v)]
        if missing:
            gh_error(f"Missing identity variables: {', '.join(missing)}")
            sys.exit(1)
        self._cred = ClientSecretCredential(
            os.environ["AZURE_TENANT_ID"],
            os.environ["AZURE_CLIENT_ID"],
            os.environ["AZURE_CLIENT_SECRET"],
        )
        self._token = None
        self._expires = 0
        self._session = requests.Session()

    def _headers(self) -> dict:
        if time.time() > self._expires - 300:
            tok = self._cred.get_token(SCOPE)
            self._token, self._expires = tok.token, tok.expires_on
        return {"Authorization": f"Bearer {self._token}"}

    def request(self, method: str, url: str, **kwargs) -> requests.Response:
        if not url.startswith("http"):
            url = API + url
        resp = None
        for attempt in range(8):
            resp = self._session.request(method, url, headers=self._headers(), timeout=120, **kwargs)
            if resp.status_code == 429 or resp.status_code >= 500:
                wait = int(resp.headers.get("Retry-After", 2 ** attempt))
                print(f"  {resp.status_code} from API, retrying in {min(wait, 60)}s")
                time.sleep(min(wait, 60))
                continue
            return resp
        return resp

    def paged(self, path: str):
        params = {}
        while True:
            resp = self.request("GET", path, params=params)
            resp.raise_for_status()
            body = resp.json()
            yield from body.get("value", [])
            token = body.get("continuationToken")
            if not token:
                return
            params = {"continuationToken": token}

    def wait_for_operation(self, resp: requests.Response) -> dict:
        """Poll a 202 long-running operation and return its result body."""
        op_url = resp.headers["Location"]
        op_id = resp.headers.get("x-ms-operation-id")
        retry_after = int(resp.headers.get("Retry-After", 2))
        deadline = time.time() + 600
        while time.time() < deadline:
            time.sleep(retry_after)
            poll = self.request("GET", op_url)
            poll.raise_for_status()
            status = poll.json().get("status")
            if status == "Succeeded":
                result = self.request("GET", f"{API}/operations/{op_id}/result")
                result.raise_for_status()
                return result.json()
            if status in ("Failed", "Cancelled"):
                err = poll.json().get("error", {})
                raise RuntimeError(f"operation {status}: {err.get('errorCode')} {err.get('message')}")
            retry_after = int(poll.headers.get("Retry-After", retry_after))
        raise TimeoutError("getDefinition did not finish within 10 minutes")

    def get_definition(self, workspace_id: str, item_id: str):
        """Return the definition dict, or None if the item type has no definition API."""
        resp = self.request("POST", f"/workspaces/{workspace_id}/items/{item_id}/getDefinition")
        if resp.status_code == 200:
            return resp.json().get("definition", {})
        if resp.status_code == 202:
            return self.wait_for_operation(resp).get("definition", {})
        try:
            code = resp.json().get("errorCode", "")
            message = resp.json().get("message", resp.text)
        except ValueError:
            code, message = "", resp.text
        if code in UNSUPPORTED_CODES or (resp.status_code == 400 and "not supported" in message.lower()):
            return None
        raise RuntimeError(f"HTTP {resp.status_code} {code}: {message}")


def parse_workspace_list(raw: str) -> list[str]:
    seen, out = set(), []
    for entry in re.split(r"[,\n]", raw):
        entry = entry.strip()
        if entry and entry.lower() not in seen:
            seen.add(entry.lower())
            out.append(entry)
    return out


def resolve_workspaces(client: FabricClient, requested: list[str]) -> list[dict]:
    visible = list(client.paged("/workspaces"))
    by_id = {w["id"].lower(): w for w in visible}
    by_name = {}
    for w in visible:
        by_name.setdefault(w["displayName"].lower(), []).append(w)

    resolved, problems = [], []
    for entry in requested:
        if GUID_RE.match(entry) and entry.lower() in by_id:
            resolved.append(by_id[entry.lower()])
            continue
        matches = by_name.get(entry.lower(), [])
        if len(matches) == 1:
            resolved.append(matches[0])
        elif len(matches) > 1:
            problems.append(f"'{entry}' matches {len(matches)} workspaces — pass the workspace ID instead")
        else:
            problems.append(f"'{entry}' not found (or the service principal is not a member of it)")

    if problems:
        for p in problems:
            gh_error(p)
        sys.exit(1)
    return resolved


def write_parts(item_dir: Path, parts: list[dict]) -> int:
    root = item_dir.resolve()
    written = 0
    for part in parts:
        rel = part.get("path", "")
        target = (item_dir / rel).resolve()
        # Refuse anything that would land outside the item folder
        if not rel or os.path.isabs(rel) or root not in target.parents:
            gh_warning(f"Skipping suspicious part path '{rel}' in {item_dir.name}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        if part.get("payloadType", "InlineBase64") == "InlineBase64":
            target.write_bytes(base64.b64decode(part.get("payload", "")))
        else:
            target.write_text(part.get("payload", ""), encoding="utf-8")
        written += 1
    return written


def archive_workspace(client: FabricClient, ws: dict, archive_root: Path) -> dict:
    ws_dir = archive_root / safe_name(ws["displayName"])
    if ws_dir.exists():
        shutil.rmtree(ws_dir)
    ws_dir.mkdir(parents=True)

    print(f"\n=== {ws['displayName']} ({ws['id']}) ===")
    items = sorted(client.paged(f"/workspaces/{ws['id']}/items"), key=lambda i: (i["type"], i["displayName"]))

    manifest = {
        "workspaceId": ws["id"],
        "workspaceName": ws["displayName"],
        "exportedAtUtc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "items": [],
    }
    used_dirs = set()
    for item in items:
        label = f"{item['displayName']}.{item['type']}"
        dir_name = safe_name(label)
        if dir_name.lower() in used_dirs:  # two items sanitise to the same name
            dir_name = safe_name(f"{item['displayName']}_{item['id'][:8]}.{item['type']}")
        used_dirs.add(dir_name.lower())

        entry = {"id": item["id"], "type": item["type"], "displayName": item["displayName"], "folder": dir_name}
        try:
            definition = client.get_definition(ws["id"], item["id"])
            if definition is None:
                entry["status"] = "skipped"
                entry["reason"] = "item type has no definition API"
                print(f"  skip    {label}")
            else:
                count = write_parts(ws_dir / dir_name, definition.get("parts", []))
                entry["status"] = "exported"
                entry["parts"] = count
                print(f"  export  {label} ({count} parts)")
        except Exception as exc:  # keep going; record and surface the failure
            entry["status"] = "failed"
            entry["reason"] = str(exc)
            gh_warning(f"{ws['displayName']}: {label} failed — {exc}")
        manifest["items"].append(entry)

    (ws_dir / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def write_step_summary(manifests: list[dict]) -> None:
    lines = ["## Fabric workspace archive", "", "| Workspace | Exported | Skipped | Failed |", "|---|---:|---:|---:|"]
    for m in manifests:
        counts = {s: sum(1 for i in m["items"] if i["status"] == s) for s in ("exported", "skipped", "failed")}
        lines.append(f"| {m['workspaceName']} | {counts['exported']} | {counts['skipped']} | {counts['failed']} |")
    failed = [(m["workspaceName"], i) for m in manifests for i in m["items"] if i["status"] == "failed"]
    if failed:
        lines += ["", "### Failed items", ""]
        lines += [f"- **{ws}** / {i['displayName']} ({i['type']}): {i['reason']}" for ws, i in failed]
    text = "\n".join(lines) + "\n"
    print("\n" + text)
    summary_file = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary_file:
        with open(summary_file, "a", encoding="utf-8") as fh:
            fh.write(text)


def main() -> None:
    requested = parse_workspace_list(os.environ.get("FABRIC_WORKSPACES", ""))
    if not requested:
        gh_error("FABRIC_WORKSPACES is empty — provide at least one workspace name or ID.")
        sys.exit(1)

    archive_root = Path(os.environ.get("ARCHIVE_DIR", "archive"))
    archive_root.mkdir(exist_ok=True)

    client = FabricClient()
    workspaces = resolve_workspaces(client, requested)
    manifests = [archive_workspace(client, ws, archive_root) for ws in workspaces]
    write_step_summary(manifests)


if __name__ == "__main__":
    main()