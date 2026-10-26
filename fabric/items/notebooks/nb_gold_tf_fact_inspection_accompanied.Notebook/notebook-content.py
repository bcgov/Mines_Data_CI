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
# nb_gold_tf_fact_inspection_accompanied — materializes stg.fact_inspection_accompanied.
# Inspections (Enhanced) report, section 5 "Accompanied". Added Oct 2026.
# Grain: one row per inspection that had at least one attendee of type "First Nations"
#   (nris_attendee_type; id 8 on 26 Oct 2026, matched by NAME so an id change can't break it).
# Checked against the report design: FY23/24 44 vs 45, FY24/25 63 vs 60, FY25/26 33 vs 32.
# Carries inspection date / Mine_SK / type from gold.fact_inspection so the model can relate to the dims.
# reload_fact (full).
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

latest("silver.nris_attendee", "attendee_id").createOrReplaceTempView("att")
latest("silver.nris_attendee_type", "attendee_type_id").createOrReplaceTempView("att_type")
spark.table("gold.fact_inspection").createOrReplaceTempView("insp")

df = spark.sql("""
    SELECT a.inspection_id,
           COUNT(*) AS first_nations_attendees,
           MAX(i.inspection_date) AS inspection_date,
           MAX(i.inspection_date_key) AS inspection_date_key,
           MAX(i.Mine_SK) AS Mine_SK,
           MAX(i.inspection_type_id) AS inspection_type_id
    FROM att a
    JOIN att_type t ON t.attendee_type_id = a.attendee_type_id
    LEFT JOIN insp i ON i.inspection_id = a.inspection_id
    WHERE LOWER(TRIM(t.attendee_type)) = 'first nations'
    GROUP BY a.inspection_id
""")
n = df.count()
print("accompanied inspections:", n, "| no inspection link:", df.filter("inspection_date IS NULL").count())
df.withColumn("fy", F.when(F.month("inspection_date") >= 4, F.year("inspection_date"))
              .otherwise(F.year("inspection_date") - 1)).groupBy("fy").count().orderBy("fy").show()
assert n > 0, "no First Nations attendees found - check silver.nris_attendee / nris_attendee_type"

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

