# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "896cd6b0-6cd0-47e5-8438-f50dde9564b8",
# META       "default_lakehouse_name": "mcm_mdp_lh1_dev",
# META       "default_lakehouse_workspace_id": "475a3e70-610e-49ae-be54-dd2c31167535",
# META       "known_lakehouses": [
# META         {
# META           "id": "896cd6b0-6cd0-47e5-8438-f50dde9564b8"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

# ════════════════════════════════════════════════════════════════════════════
# GOLD REFERENCE — ref_mmo_published   (MMO / Major Mines report, Option 1 wireframe)
# Published figures that are NOT in MDS, so the report can show them beside MDS data.
# Values are copied from Romil's MMO wireframe (Option 1, Oct 2026), which cites:
#   CIM & CPO annual report 2024/25 and the 2025/26 annual service plan report.
# verified = False until Raj / MMO confirm each value against the source report.
# To update: edit ROWS below, commit, deploy. Rebuilt in full on every Gold run.
# ════════════════════════════════════════════════════════════════════════════
from pyspark.sql import functions as F, types as T

CIM = "CIM & CPO annual report 2024/25"
ASP = "2025/26 annual service plan report"

# metric_key, category, sort_order, value, unit, period, source, note
ROWS = [
    ("producing_mines",        "Total",                          0,  17,   "count",  "2024/25", CIM, "Mines that actually produced"),
    ("producing_by_commodity", "Metal",                          10, 10,   "count",  "2024/25", CIM, ""),
    ("producing_by_commodity", "Coal",                           11, 7,    "count",  "2024/25", CIM, ""),
    ("projects_approved",      "Total",                          0,  6,    "count",  "2025/26", ASP, "Three of them were priority projects"),
    ("approval_days",          "Five-year average",              20, 89,   "days",   "2025/26", ASP, "Major mine screening"),
    ("approval_days",          "2025/26",                        21, 31,   "days",   "2025/26", ASP, "Major mine screening"),
    ("approval_months",        "Run separately (typical)",       22, 42,   "months", "2025/26", ASP, "Assessment and permit"),
    ("approval_months",        "Coordinated (Mount Milligan)",   23, 10,   "months", "2025/26", ASP, "Assessment and permit together"),
    ("inspections_share",      "Major mines",                    30, 518,  "count",  "2024/25", CIM, ""),
    ("inspections_share",      "Regional mines",                 31, 1331, "count",  "2024/25", CIM, ""),
    ("incidents_share",        "Major mines",                    30, 546,  "count",  "2024/25", CIM, "Reportable incidents"),
    ("incidents_share",        "Regional mines",                 31, 52,   "count",  "2024/25", CIM, "Reportable incidents"),
    ("major_insp_discipline",  "H&S generalist",                 40, 205,  "count",  "2024/25", CIM, "Inspections at major mines"),
    ("major_insp_discipline",  "H&S specialist",                 41, 162,  "count",  "2024/25", CIM, "Inspections at major mines"),
    ("major_insp_discipline",  "Environmental & reclamation",    42, 72,   "count",  "2024/25", CIM, "Inspections at major mines"),
    ("major_insp_discipline",  "Geotechnical",                   43, 69,   "count",  "2024/25", CIM, "Inspections at major mines"),
    ("major_insp_discipline",  "Permitting",                     44, 7,    "count",  "2024/25", CIM, "Inspections at major mines"),
    ("major_insp_discipline",  "Emerging technology",            45, 3,    "count",  "2024/25", CIM, "Inspections at major mines"),
]

LABELS = {
    "producing_mines": "Producing mines", "producing_by_commodity": "Producing mines by commodity",
    "projects_approved": "Major projects approved", "approval_days": "Major mine screening (days)",
    "approval_months": "Assessment and permit (months)", "inspections_share": "Inspections",
    "incidents_share": "Reportable incidents", "major_insp_discipline": "Inspections at major mines",
}
schema = T.StructType([
    T.StructField("metric_key", T.StringType()), T.StructField("category", T.StringType()),
    T.StructField("sort_order", T.IntegerType()), T.StructField("value", T.DoubleType()),
    T.StructField("unit", T.StringType()), T.StructField("period", T.StringType()),
    T.StructField("source", T.StringType()), T.StructField("note", T.StringType()),
])
df = spark.createDataFrame([(k, c, s, float(v), u, p, src, n) for (k, c, s, v, u, p, src, n) in ROWS], schema) \
          .withColumn("verified", F.lit(False)) \
          .withColumn("metric_label", F.create_map(*[F.lit(x) for kv in LABELS.items() for x in kv])[F.col("metric_key")])

spark.sql("CREATE SCHEMA IF NOT EXISTS gold")
(df.write.format("delta").mode("overwrite").option("overwriteSchema", "true")
    .saveAsTable("gold.ref_mmo_published"))
print(f"built gold.ref_mmo_published: {df.count()} rows")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
