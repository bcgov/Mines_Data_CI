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
# GOLD TRANSFORM — fact_major_project   (MMO / Major Mines corporate report)
#   Cell 1  imports + Spark properties              (this cell)
#   Cell 2  derive TARGET_TABLE from notebook name + register sources
#   Cell 3  drop the existing stg table
#   Cell 4  SparkSQL business logic -> DataFrame
#   Cell 5  write the DataFrame to TARGET_TABLE
#
# Grain: one row per project summary (project_summary_id is the natural PK).
# Fact type: reload_fact — full rebuild every run (source is small, ~100 rows).
# Level 1 in Gold DAG — depends on: dim_mine, dim_date.
#
# Mirrors Metabase dashboard 393 cards 3387-3391 (R. Gulati):
#   a project is flagged by the Act(s) it is authorized under, via
#   project_summary_authorization -> project_summary_authorization_type
#   where project_summary_authorization_type_group_id is
#   'MINES_ACT' or 'ENVIRONMENTAL_MANAGMENT_ACT' (sic — source spelling).
#   act_group then buckets each project once:
#     Mines Act only | EMA only | Both | Other
#   so the four buckets add up to the total (107 / 33 / 33 / 24 / 17 on 2 Oct 2026).
#
# Date basis (R. Gulati, 5 Oct 2026): submission_date on project_summary.
#   Report shows last 3 / last 6 months by submission_date, MA + EMA projects only.
#   No FY-vs-last-FY delta for this report.
# ════════════════════════════════════════════════════════════════════════════
from pyspark.sql import functions as F  # noqa: F401
from notebookutils import mssparkutils

spark.conf.set("spark.sql.parquet.datetimeRebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY")
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "LEGACY")

CTRL = {"dl_load_id", "bronze_file_name", "bronze_file_timestamp", "bronze_load_date",
        "dl_load_ts", "dl_rowhash", "silver_load_ts"}

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

spark.table("silver.project_summary").createOrReplaceTempView("src_project_summary")
spark.table("silver.project_summary_authorization").createOrReplaceTempView("src_psa")
spark.table("silver.project_summary_authorization_type").createOrReplaceTempView("src_psat")

spark.table("gold.dim_mine").createOrReplaceTempView("gold_dim_mine")
spark.table("gold.dim_date").createOrReplaceTempView("gold_dim_date")

print("notebook:", NOTEBOOK_NAME, "-> target:", TARGET_TABLE)
print("project_summary source rows:", spark.table("src_project_summary").count())

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

# BUSINESS LOGIC — build fact_major_project.
#
# Step 1: one row per project with its two Act flags (same as Metabase project_flags CTE).
spark.sql("""
    SELECT
        ps.project_summary_id,
        MAX(CASE WHEN psat.project_summary_authorization_type_group_id = 'MINES_ACT'
                 THEN 1 ELSE 0 END)                                  AS has_mines_act,
        MAX(CASE WHEN psat.project_summary_authorization_type_group_id = 'ENVIRONMENTAL_MANAGMENT_ACT'
                 THEN 1 ELSE 0 END)                                  AS has_ema
    FROM src_project_summary ps
    LEFT JOIN src_psa psa
        ON ps.project_summary_guid = psa.project_summary_guid
    LEFT JOIN src_psat psat
        ON psa.project_summary_authorization_type = psat.project_summary_authorization_type
    WHERE ps.project_summary_id IS NOT NULL
    GROUP BY ps.project_summary_id
""").createOrReplaceTempView("project_flags")

# Step 2: attach the project attributes, date key, mine key and the act_group bucket.
df = spark.sql("""
    SELECT
        ps.project_summary_id,
        ps.project_summary_guid,
        ps.project_summary_title,
        ps.status_code,

        -- Surrogate keys
        dm.Mine_SK,
        sdd.Date_SK                                   AS Submission_Date_SK,

        -- Dates
        CAST(ps.submission_date AS DATE)              AS submission_date,
        CAST(ps.create_timestamp AS DATE)             AS create_date,

        -- Act flags and the single bucket each project falls into
        f.has_mines_act,
        f.has_ema,
        CASE
            WHEN f.has_mines_act = 1 AND f.has_ema = 0 THEN 'Mines Act only'
            WHEN f.has_mines_act = 0 AND f.has_ema = 1 THEN 'EMA only'
            WHEN f.has_mines_act = 1 AND f.has_ema = 1 THEN 'Both'
            ELSE 'Other'
        END                                           AS act_group,
        CASE WHEN f.has_mines_act = 1 OR f.has_ema = 1 THEN 1 ELSE 0 END
                                                      AS is_ma_or_ema,

        ps.deleted_ind
    FROM src_project_summary ps
    JOIN project_flags f
        ON ps.project_summary_id = f.project_summary_id
    LEFT JOIN gold_dim_mine dm
        ON ps.mine_guid = dm.mine_guid
        AND dm.dl_iscurrent = 1
    LEFT JOIN gold_dim_date sdd
        ON sdd.full_date = CAST(ps.submission_date AS DATE)
    WHERE ps.project_summary_id IS NOT NULL
""")
print("built dataframe:", df.count(), "rows,", len(df.columns), "cols")
# Metabase 3387 applies no deleted filter; deleted_ind is kept as a column so the
# model can match Metabase (no filter) or exclude deleted rows later if Raj wants.

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(df.write.format("delta").mode("overwrite")
   .option("overwriteSchema", "true").saveAsTable(TARGET_TABLE))
print("wrote", df.count(), "rows to", TARGET_TABLE)

# Quick tie-out against Metabase 3387-3391 (expected 2 Oct 2026: 107 / 33 / 33 / 24 / 17)
spark.sql(f"""
    SELECT act_group, COUNT(*) AS projects
    FROM {TARGET_TABLE}
    GROUP BY act_group
    ORDER BY act_group
""").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
