# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

# nb_refresh_gold_models - full refresh of every "Gold ..." semantic model in this workspace,
# then wait until each one finishes. Last step of pl_bronze_to_gold, so the reports show the
# data the Gold build just wrote (incl. calculated tables like incident_week).
# Same REST calls as fabric/deploy.py. Fails the notebook (and the pipeline) if any refresh fails.
import time
import requests

PBI_API = "https://api.powerbi.com/v1.0/myorg"
MODEL_PREFIX = "Gold "
TIMEOUT_SECONDS = 1800
POLL_SECONDS = 15

workspace_id = notebookutils.runtime.context["currentWorkspaceId"]
headers = {"Authorization": f"Bearer {notebookutils.credentials.getToken('pbi')}"}

resp = requests.get(f"{PBI_API}/groups/{workspace_id}/datasets", headers=headers, timeout=60)
resp.raise_for_status()
models = {d["name"]: d["id"] for d in resp.json().get("value", []) if d["name"].startswith(MODEL_PREFIX)}
print(f"workspace {workspace_id}: {len(models)} Gold models -> {sorted(models)}")
if not models:
    raise RuntimeError("No 'Gold ...' semantic models found in this workspace")

pending = {}
for name, model_id in models.items():
    r = requests.post(f"{PBI_API}/groups/{workspace_id}/datasets/{model_id}/refreshes",
                      headers=headers, json={"type": "full"}, timeout=60)
    if r.status_code not in (200, 202):
        raise RuntimeError(f"Could not start refresh of '{name}': {r.status_code} {r.text}")
    print(f"refresh started: {name}")
    pending[name] = model_id

failed = []
deadline = time.monotonic() + TIMEOUT_SECONDS
while pending and time.monotonic() < deadline:
    time.sleep(POLL_SECONDS)
    for name, model_id in list(pending.items()):
        r = requests.get(f"{PBI_API}/groups/{workspace_id}/datasets/{model_id}/refreshes?$top=1",
                         headers=headers, timeout=60)
        r.raise_for_status()
        latest = (r.json().get("value") or [{}])[0]
        status = latest.get("status")
        if status == "Completed":
            print(f"refresh completed: {name}")
            del pending[name]
        elif status in ("Failed", "Cancelled", "Disabled"):
            print(f"refresh {status.lower()}: {name} - {latest.get('serviceExceptionJson', '')}")
            failed.append(name)
            del pending[name]

failed += [f"{n} (timed out)" for n in pending]
if failed:
    raise RuntimeError("Semantic model refresh failed for: " + ", ".join(failed))
print("all Gold models refreshed")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
