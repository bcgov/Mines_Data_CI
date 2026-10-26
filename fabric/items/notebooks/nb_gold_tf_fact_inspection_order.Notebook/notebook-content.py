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
# nb_gold_tf_fact_inspection_order — materializes stg.fact_inspection_order (Gold orchestrator).
# Inspections (Enhanced) report, section 4 "What we found". Added Oct 2026.
# Grain: one row per NRIS order item. order_type = Stop | Warning | Request | Advisory.
#   "Orders" in the report = Stop items (formal orders under the Mines Act s.15);
#   warnings, requests and advisories are kept for context.
# Link: order item -> nris_inspected_location -> inspection_id -> gold.fact_inspection
#   (gives inspection date, Mine_SK and inspection type, so the model can relate to the same dims).
# Category (design groups) from the first non-compliance on the order:
#   noncompliance_permit -> Permit conditions (unless the order also cites HSRC part 4-7 or 10)
#   HSRC code section part 4, 5, 7  -> Mechanical and electrical (machinery, electrical, hoists)
#   HSRC part 6                      -> Ground control and geotechnical (mine design)
#   HSRC part 10                     -> Reclamation and environment
#   anything else (parts 1-3, 8, 9)  -> Health and safety
# due_date: stop = completion_date (comply-by date); warning/request = respond_date.
# reload_fact (full) — the source tables are complete snapshots.
# ════════════════════════════════════════════════════════════════════════════
from pyspark.sql import functions as F
from pyspark.sql import Window
from notebookutils import mssparkutils

spark.conf.set("spark.sql.parquet.datetimeRebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "LEGACY")

NB_PREFIX  = "nb_gold_tf_"
STG_SCHEMA = "stg"
NOTEBOOK_NAME = mssparkutils.runtime.context.get("currentNotebookName")
assert NOTEBOOK_NAME, "could not resolve current notebook name from runtime context"
assert NOTEBOOK_NAME.startswith(NB_PREFIX), f"notebook '{NOTEBOOK_NAME}' must be named '{NB_PREFIX}<object>'"
OBJECT_NAME  = NOTEBOOK_NAME[len(NB_PREFIX):]
TARGET_TABLE = f"{STG_SCHEMA}.{OBJECT_NAME}"
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {STG_SCHEMA}")


def latest(table, key):
    """One row per key from a silver NRIS table (FULL loads; keep the newest silver copy)."""
    w = Window.partitionBy(key).orderBy(F.col("silver_load_ts").desc())
    return spark.table(table).withColumn("_rn", F.row_number().over(w)).filter("_rn = 1").drop("_rn")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Sources (silver, deduped) + the inspection fact for date / mine / type.
latest("silver.nris_inspected_location", "inspected_location_id").createOrReplaceTempView("loc")
latest("silver.nris_order_stop_detail", "order_stop_detail_id").createOrReplaceTempView("stop")
latest("silver.nris_order_warning_detail", "order_warning_detail_id").createOrReplaceTempView("warn")
latest("silver.nris_order_request_detail", "order_request_detail_id").createOrReplaceTempView("req")
latest("silver.nris_order_advisory_detail", "order_advisory_detail_id").createOrReplaceTempView("adv")
latest("silver.nris_noncompliance_legislation", "noncompliance_legislation_id").createOrReplaceTempView("ncl")
latest("silver.nris_noncompliance_permit", "noncompliance_permit_id").createOrReplaceTempView("ncp")
latest("silver.nris_legislation_act_section", "legislation_act_section_id").createOrReplaceTempView("sec")
spark.table("gold.fact_inspection").createOrReplaceTempView("insp")

# First non-compliance per stop order -> code section -> design category.
spark.sql("""
    WITH leg AS (
        SELECT n.order_stop_detail_id, s.section,
               ROW_NUMBER() OVER (PARTITION BY n.order_stop_detail_id ORDER BY n.noncompliance_legislation_id) AS rn
        FROM ncl n LEFT JOIN sec s ON s.legislation_act_section_id = n.legislation_act_section_id
    ),
    prm AS (SELECT DISTINCT order_stop_detail_id FROM ncp)
    SELECT o.order_stop_detail_id,
           l.section AS code_section,
           CASE
             WHEN p.order_stop_detail_id IS NOT NULL AND l.section IS NULL THEN 'Permit conditions'
             WHEN TRY_CAST(SPLIT(l.section, '[.]')[0] AS INT) IN (4, 5, 7) THEN 'Mechanical and electrical'
             WHEN TRY_CAST(SPLIT(l.section, '[.]')[0] AS INT) = 6 THEN 'Ground control and geotechnical'
             WHEN TRY_CAST(SPLIT(l.section, '[.]')[0] AS INT) = 10 THEN 'Reclamation and environment'
             WHEN p.order_stop_detail_id IS NOT NULL THEN 'Permit conditions'
             ELSE 'Health and safety'
           END AS order_category
    FROM stop o
    LEFT JOIN leg l ON l.order_stop_detail_id = o.order_stop_detail_id AND l.rn = 1
    LEFT JOIN prm p ON p.order_stop_detail_id = o.order_stop_detail_id
""").createOrReplaceTempView("stop_cat")

df = spark.sql("""
    WITH items AS (
        SELECT 'Stop' AS order_type, o.order_stop_detail_id AS order_detail_id, o.inspected_location_id,
               CAST(o.order_number AS STRING) AS order_number, o.stop_type, o.stop_status, o.response_status,
               CAST(o.response_received AS DATE) AS response_received, CAST(o.completion_date AS DATE) AS due_date,
               c.order_category, c.code_section
        FROM stop o LEFT JOIN stop_cat c ON c.order_stop_detail_id = o.order_stop_detail_id
        UNION ALL
        SELECT 'Warning', w.order_warning_detail_id, w.inspected_location_id, NULL, NULL, NULL, NULL,
               NULL, CAST(w.respond_date AS DATE), NULL, NULL
        FROM warn w
        UNION ALL
        SELECT 'Request', r.order_request_detail_id, r.inspected_location_id, NULL, NULL, NULL, NULL,
               NULL, CAST(r.respond_date AS DATE), NULL, NULL
        FROM req r
        UNION ALL
        SELECT 'Advisory', a.order_advisory_detail_id, a.inspected_locations_id, NULL, NULL, NULL, NULL,
               NULL, NULL, NULL, NULL
        FROM adv a
    )
    SELECT CONCAT(UPPER(t.order_type), '-', CAST(t.order_detail_id AS STRING)) AS order_key,
           t.order_type, t.order_detail_id, t.inspected_location_id, l.inspection_id,
           t.order_number, t.stop_type, t.stop_status, t.response_status,
           t.response_received, t.due_date, t.order_category, t.code_section,
           CASE WHEN t.order_type = 'Stop' AND t.stop_status = 'Open' THEN 1 ELSE 0 END AS is_open,
           CASE WHEN t.order_type = 'Stop' AND t.stop_status = 'Closed' THEN 1 ELSE 0 END AS is_closed,
           CASE WHEN t.order_type = 'Stop' AND t.stop_status = 'Open' AND t.response_status = 'Required'
                     AND t.due_date < CURRENT_DATE() THEN 1 ELSE 0 END AS is_response_overdue,
           CASE WHEN t.order_type = 'Stop' AND t.stop_status = 'Open' AND t.response_status = 'Required'
                     AND t.due_date < CURRENT_DATE() THEN DATEDIFF(CURRENT_DATE(), t.due_date) END AS days_overdue,
           CASE WHEN t.response_received IS NOT NULL AND t.due_date IS NOT NULL
                THEN CASE WHEN t.response_received <= t.due_date THEN 1 ELSE 0 END END AS is_response_on_time,
           CASE WHEN t.response_received IS NOT NULL
                THEN DATEDIFF(t.response_received, CAST(i.inspection_date AS DATE)) END AS days_to_response,
           i.inspection_date, i.inspection_date_key, i.Mine_SK, i.inspection_type_id
    FROM items t
    LEFT JOIN loc l ON l.inspected_location_id = t.inspected_location_id
    LEFT JOIN insp i ON i.inspection_id = l.inspection_id
""")
n = df.count()
dupes = df.groupBy("order_key").count().filter("count > 1").count()
no_insp = df.filter("inspection_id IS NULL").count()
print("built dataframe:", n, "rows | duplicate order_key:", dupes, "| no inspection link:", no_insp)
df.groupBy("order_type").count().show()
df.filter("order_type = 'Stop'").groupBy("order_category").count().orderBy(F.desc("count")).show(truncate=False)
assert dupes == 0, "fact_inspection_order grain broken: duplicate order_key"

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

spark.sql(f"DROP TABLE IF EXISTS {TARGET_TABLE}")
print("dropped (if existed):", TARGET_TABLE)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(df.write.format("delta").mode("overwrite")
   .option("overwriteSchema", "true").saveAsTable(TARGET_TABLE))
print("wrote", df.count(), "rows to", TARGET_TABLE)

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

