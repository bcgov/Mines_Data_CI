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
# Projects (Enhanced) columns, added 2026-11-10 for Romil's Major Mines Projects design:
#   project_lead_name         project.project_lead_party_guid -> party (55% filled at source)
#   application_status_code   best status of the project's major_mine_application rows
#   application_received_date first application create_timestamp
#   application_complete_date update_timestamp of a COM application (proxy: Core keeps no history)
#   irt_status_code           information_requirements_table status, if any
#   proxy_stage / proxy_stage_order  Core keeps current status only, so the stage is derived:
#     Withdrawn (WDN) > Complete (summary COM or application COM) > Application review
#     > Information requirements > Emerging (draft, DFT) > Pre-application
#   days_since_submission     today - submission_date (open projects only)
#   is_open                   not Complete / Withdrawn
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
spark.table("silver.project").createOrReplaceTempView("src_project")
spark.table("silver.party").createOrReplaceTempView("src_party")
spark.table("silver.major_mine_application").createOrReplaceTempView("src_application")
spark.table("silver.information_requirements_table").createOrReplaceTempView("src_irt")

# one current row per mine_guid, so the mine join cannot fan out a project (488 rows vs 420 projects, 9 Oct 2026)
spark.sql("""
    SELECT mine_guid, MAX(Mine_SK) AS Mine_SK, 1 AS dl_iscurrent
    FROM gold.dim_mine
    WHERE dl_iscurrent = 1
    GROUP BY mine_guid
""").createOrReplaceTempView("mmp_dim_mine")
# Own view names: the orchestrator runs a level's notebooks in parallel in one Spark
# session, and other notebooks register "gold_dim_mine" as the full dim_mine.
spark.table("gold.dim_date").createOrReplaceTempView("mmp_dim_date")

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

# Step 1b: application, IRT and lead per project (added 2026-11-10).
spark.sql("""
    SELECT
        project_guid,
        MIN(create_timestamp)                                              AS application_received_ts,
        MAX(CASE WHEN status_code = 'COM' THEN update_timestamp END)       AS application_complete_ts,
        MAX(CASE status_code WHEN 'COM' THEN 4 WHEN 'CHR' THEN 3
                             WHEN 'UNR' THEN 2 WHEN 'SUB' THEN 1 ELSE 0 END) AS application_rank
    FROM src_application
    WHERE deleted_ind = 0
    GROUP BY project_guid
""").createOrReplaceTempView("project_application")

spark.sql("""
    SELECT project_guid, MAX(status_code) AS irt_status_code
    FROM src_irt
    WHERE deleted_ind = 0
    GROUP BY project_guid
""").createOrReplaceTempView("project_irt")

spark.sql("""
    SELECT
        p.project_guid,
        TRIM(CONCAT_WS(' ', pa.first_name, pa.party_name))                 AS project_lead_name,
        p.mine_guid                                                        AS project_mine_guid,
        p.project_title                                                    AS project_title
    FROM src_project p
    LEFT JOIN src_party pa
        ON pa.party_guid = p.project_lead_party_guid
""").createOrReplaceTempView("project_lead")

# Step 2: attach the project attributes, date key, mine key and the act_group bucket.
df = spark.sql("""
    SELECT
        ps.project_summary_id,
        ps.project_summary_guid,
        COALESCE(pl.project_title, ps.project_summary_title) AS project_summary_title,  -- title lives on project (10 Nov 2026)
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

        -- Projects (Enhanced), added 2026-11-10
        NULLIF(pl.project_lead_name, '')              AS project_lead_name,
        CASE pa.application_rank WHEN 4 THEN 'COM' WHEN 3 THEN 'CHR' WHEN 2 THEN 'UNR'
                                 WHEN 1 THEN 'SUB' END
                                                      AS application_status_code,
        CAST(pa.application_received_ts AS DATE)      AS application_received_date,
        CAST(pa.application_complete_ts AS DATE)      AS application_complete_date,
        pi.irt_status_code,
        CASE
            WHEN ps.status_code = 'WDN'                              THEN 'Withdrawn'
            WHEN ps.status_code = 'COM' OR pa.application_rank = 4   THEN 'Complete'
            WHEN pa.application_rank >= 1                            THEN 'Application review'
            WHEN pi.irt_status_code IS NOT NULL                      THEN 'Information requirements'
            WHEN ps.status_code = 'DFT'                              THEN 'Emerging (draft)'
            ELSE 'Pre-application'
        END                                           AS proxy_stage,
        CASE
            WHEN ps.status_code = 'WDN'                              THEN 6
            WHEN ps.status_code = 'COM' OR pa.application_rank = 4   THEN 5
            WHEN pa.application_rank >= 1                            THEN 4
            WHEN pi.irt_status_code IS NOT NULL                      THEN 3
            WHEN ps.status_code = 'DFT'                              THEN 1
            ELSE 2
        END                                           AS proxy_stage_order,
        CASE WHEN ps.status_code = 'WDN' OR ps.status_code = 'COM' OR pa.application_rank = 4
             THEN 0 ELSE 1 END                        AS is_open,
        CASE WHEN ps.status_code = 'WDN' OR ps.status_code = 'COM' OR pa.application_rank = 4
                  OR ps.submission_date IS NULL THEN NULL
             ELSE DATEDIFF(CURRENT_DATE(), CAST(ps.submission_date AS DATE)) END
                                                      AS days_since_submission,

        ps.deleted_ind
    FROM src_project_summary ps
    JOIN project_flags f
        ON ps.project_summary_id = f.project_summary_id
    LEFT JOIN project_lead pl
        ON pl.project_guid = ps.project_guid
    LEFT JOIN project_application pa
        ON pa.project_guid = ps.project_guid
    LEFT JOIN project_irt pi
        ON pi.project_guid = ps.project_guid
    -- project_summary.mine_guid is filled for 1 of 121 projects (10 Nov 2026); project.mine_guid
    -- is filled for every project, so use it and fall back to project_summary.
    LEFT JOIN mmp_dim_mine dm
        ON COALESCE(pl.project_mine_guid, ps.mine_guid) = dm.mine_guid
        AND dm.dl_iscurrent = 1
    LEFT JOIN mmp_dim_date sdd
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

# Stage tie-out (10 Nov 2026, live rows: Pre-application 68, Emerging 20, Application review 19,
# Complete 10, Withdrawn 2, Information requirements 2; 66 of 121 with a lead)
spark.sql(f"""
    SELECT proxy_stage, COUNT(*) AS projects, COUNT(project_lead_name) AS with_lead
    FROM {TARGET_TABLE} WHERE deleted_ind = 0
    GROUP BY proxy_stage ORDER BY projects DESC
""").show()

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
