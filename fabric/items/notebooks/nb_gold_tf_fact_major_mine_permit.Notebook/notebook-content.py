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
# GOLD TRANSFORM — fact_major_mine_permit   (MMO / Major Mines corporate report)
#   Cell 1  imports + Spark properties              (this cell)
#   Cell 2  derive TARGET_TABLE from notebook name + register sources
#   Cell 3  drop the existing stg table
#   Cell 4  SparkSQL business logic -> DataFrame
#   Cell 5  write the DataFrame to TARGET_TABLE
#
# Grain: one row per mine + permit, as in public.mine_summary_view.
# Fact type: reload_fact — full rebuild every run (~200 rows).
# Level 1 in Gold DAG — depends on: dim_mine, dim_date.
#
# Mirrors Metabase dashboard 393 card 3392 "Major Mines Information" (R. Gulati):
#   * source = mine_summary_view
#   * major_mine_d = 'Major Mine'
#   * mine_operation_status_d IN ('Closed', 'Not Started', 'Operating')
#   * permit_status: 'O' -> Open, 'C' -> Closed
# We keep every Major Mine row and flag the three statuses with is_in_report_scope,
# so the model can match Metabase (scope = 1) and still show the rest if asked.
# No DISTINCT, same as Metabase, so the row count ties out (205 rows on 7 Oct 2026).
# ════════════════════════════════════════════════════════════════════════════
from pyspark.sql import functions as F  # noqa: F401
from notebookutils import mssparkutils

spark.conf.set("spark.sql.parquet.datetimeRebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "LEGACY")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

NB_PREFIX     = "nb_gold_tf_"
STG_SCHEMA    = "stg"
NOTEBOOK_NAME = mssparkutils.runtime.context.get("currentNotebookName")
assert NOTEBOOK_NAME, "could not resolve current notebook name from runtime context"
assert NOTEBOOK_NAME.startswith(NB_PREFIX), f"notebook must be named '{NB_PREFIX}<object>'"
OBJECT_NAME   = NOTEBOOK_NAME[len(NB_PREFIX):]
TARGET_TABLE  = f"{STG_SCHEMA}.{OBJECT_NAME}"
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {STG_SCHEMA}")

spark.table("silver.mine_summary_view").createOrReplaceTempView("src_msv")
spark.table("gold.dim_mine").createOrReplaceTempView("gold_dim_mine")
spark.table("gold.dim_date").createOrReplaceTempView("gold_dim_date")

print("notebook:", NOTEBOOK_NAME, "-> target:", TARGET_TABLE)
print("mine_summary_view source rows:", spark.table("src_msv").count())

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

# BUSINESS LOGIC — build fact_major_mine_permit (Metabase card 3392).
df = spark.sql("""
    SELECT
        msv.permit_id,
        msv.permit_no,

        -- Surrogate keys
        dm.Mine_SK,
        idd.Date_SK                                   AS Permit_Issue_Date_SK,

        -- Mine attributes (denormalised for the drill table)
        msv.mine_guid,
        msv.mine_name,
        msv.mine_number,
        msv.mine_region,
        msv.operation_status,
        msv.major_mine_d                              AS major_mine_desc,
        msv.mine_operation_status_d                   AS mine_operation_status_desc,

        -- Permit attributes
        msv.permit_status_code,
        CASE WHEN msv.permit_status_code = 'O' THEN 'Open'
             WHEN msv.permit_status_code = 'C' THEN 'Closed'
             ELSE msv.permit_status_code END          AS permit_status,
        CAST(msv.issue_date AS DATE)                  AS permit_issue_date,

        -- Metabase 3392 scope flag
        CASE WHEN msv.mine_operation_status_d IN ('Closed', 'Not Started', 'Operating')
             THEN 1 ELSE 0 END                        AS is_in_report_scope

    FROM src_msv msv
    LEFT JOIN gold_dim_mine dm
        ON dm.mine_guid = msv.mine_guid
        AND dm.dl_iscurrent = 1
    LEFT JOIN gold_dim_date idd
        ON idd.full_date = CAST(msv.issue_date AS DATE)
    WHERE msv.major_mine_d = 'Major Mine'
""")
print("built dataframe:", df.count(), "rows,", len(df.columns), "cols")

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(df.write.format("delta").mode("overwrite")
   .option("overwriteSchema", "true").saveAsTable(TARGET_TABLE))
print("wrote", df.count(), "rows to", TARGET_TABLE)

# Tie-out: Metabase 3392 returned 205 rows on 7 Oct 2026 (is_in_report_scope = 1).
spark.sql(f"""
    SELECT is_in_report_scope, COUNT(*) AS rows,
           COUNT(DISTINCT mine_guid) AS mines, COUNT(DISTINCT permit_id) AS permits
    FROM {TARGET_TABLE}
    GROUP BY is_in_report_scope
""").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
