{
  "name": "pl_daily_load",
  "properties": {
    "description": "Scheduled master: pl_ingest_mds + pl_ingest_mto, then pl_bronze_to_gold.",
    "activities": {{.activities_json}},
    "concurrency": 1,
    "annotations": []
  }
}
