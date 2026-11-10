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
# GOLD TRANSFORM — fact_notice_of_departure   (Major Mines Projects report, page 4)
#   Cell 1  imports + Spark properties              (this cell)
#   Cell 2  derive TARGET_TABLE from notebook name + register sources
#   Cell 3  drop the existing stg table
#   Cell 4  SparkSQL business logic -> DataFrame
#   Cell 5  write the DataFrame to TARGET_TABLE
#
# Grain: one row per notice of departure (nod_guid). Added 2026-11-10.
# Fact type: reload_fact — full rebuild every run (source is small, ~170 rows).
# Level 1 in Gold DAG — depends on: dim_mine, dim_date.
#
# Source: silver.notice_of_departure (Core). Columns used: nod_no, nod_title, nod_type
#   (potentially_substantial / non_substantial), nod_status, submission_timestamp,
#   mine_guid, permit_guid, update_timestamp, deleted_ind.
# Decision date: Core has no decision date column. Proxy = update_timestamp when the
#   status is a determination (determined_* / self_determined_*). Withdrawn is closed
#   but not decided.
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

spark.table("silver.notice_of_departure").createOrReplaceTempView("src_nod")

# one current row per mine_guid, so the mine join cannot fan out (same as fact_major_project)
spark.sql("""
    SELECT mine_guid, MAX(Mine_SK) AS Mine_SK
    FROM gold.dim_mine
    WHERE dl_iscurrent = 1
    GROUP BY mine_guid
""").createOrReplaceTempView("nod_dim_mine")
# Own view names: the orchestrator runs a level's notebooks in parallel in one Spark
# session, and other notebooks register "gold_dim_mine" as the full dim_mine.
spark.table("gold.dim_date").createOrReplaceTempView("nod_dim_date")

print("notebook:", NOTEBOOK_NAME, "-> target:", TARGET_TABLE)
print("notice_of_departure source rows:", spark.table("src_nod").count())


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

df = spark.sql("""
    SELECT
        n.nod_guid,
        n.nod_no,
        n.nod_title,
        n.nod_type,
        CASE n.nod_type
            WHEN 'potentially_substantial' THEN 'Potentially substantial'
            WHEN 'non_substantial'         THEN 'Non-substantial'
            ELSE INITCAP(REPLACE(n.nod_type, '_', ' '))
        END                                           AS nod_type_label,
        n.nod_status,
        CASE n.nod_status
            WHEN 'pending_review'                  THEN 'Pending review'
            WHEN 'in_review'                       THEN 'In review'
            WHEN 'information_required'            THEN 'Information required'
            WHEN 'determined_non_substantial'      THEN 'Determined non-substantial'
            WHEN 'determined_substantial'          THEN 'Determined substantial'
            WHEN 'self_determined_non_substantial' THEN 'Self-determined non-substantial'
            WHEN 'withdrawn'                       THEN 'Withdrawn'
            ELSE INITCAP(REPLACE(n.nod_status, '_', ' '))
        END                                           AS nod_status_label,
        CASE WHEN n.nod_status LIKE '%determined%' THEN 1 ELSE 0 END    AS is_decided,
        CASE WHEN n.nod_status LIKE '%determined%' OR n.nod_status = 'withdrawn'
             THEN 0 ELSE 1 END                        AS is_open,
        n.mine_guid,
        n.permit_guid,

        -- Surrogate keys
        dm.Mine_SK,
        sdd.Date_SK                                   AS Submission_Date_SK,

        -- Dates
        CAST(n.submission_timestamp AS DATE)          AS submission_date,
        CASE WHEN n.nod_status LIKE '%determined%'
             THEN CAST(n.update_timestamp AS DATE) END AS decision_date,
        CASE WHEN n.nod_status LIKE '%determined%'
             THEN DATEDIFF(CAST(n.update_timestamp AS DATE), CAST(n.submission_timestamp AS DATE))
        END                                           AS days_to_decision,
        CASE WHEN n.nod_status LIKE '%determined%' OR n.nod_status = 'withdrawn' THEN NULL
             ELSE DATEDIFF(CURRENT_DATE(), CAST(n.submission_timestamp AS DATE))
        END                                           AS days_open,

        n.deleted_ind
    FROM src_nod n
    LEFT JOIN nod_dim_mine dm
        ON n.mine_guid = dm.mine_guid
    LEFT JOIN nod_dim_date sdd
        ON sdd.full_date = CAST(n.submission_timestamp AS DATE)
    WHERE n.nod_guid IS NOT NULL
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

# Tie-out (10 Nov 2026, live rows: 169 notices; determined_non_substantial 73,
# self_determined_non_substantial 30, pending_review 23, withdrawn 17,
# determined_substantial 15, in_review 7, information_required 4)
spark.sql(f"""
    SELECT nod_status_label, COUNT(*) AS notices
    FROM {TARGET_TABLE} WHERE deleted_ind = 0
    GROUP BY nod_status_label ORDER BY notices DESC
""").show()


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

