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
# GOLD TRANSFORM — fact_permit_bond   (MMO / Major Mines corporate report)
#   Cell 1  imports + Spark properties              (this cell)
#   Cell 2  derive TARGET_TABLE from notebook name + register sources
#   Cell 3  drop the existing stg table
#   Cell 4  SparkSQL business logic -> DataFrame
#   Cell 5  write the DataFrame to TARGET_TABLE
#
# Grain: one row per C/M permit (permit_id is the natural PK).
# Fact type: reload_fact — full rebuild every run (~100 rows).
# Level 1 in Gold DAG — depends on: dim_mine, dim_date.
#
# Mirrors Metabase dashboard 393 card 2868 "C/M permits for Bond amounts" (R. Gulati):
#   * C/M permits only — permit_no NOT LIKE p-, pm-, g-, q-, mx-, cx- (coal + mineral).
#   * Bond side: active bonds only (bond_status_code = 'ACT'), amount summed per permit,
#     latest bond issue_date. A permit with no active bond is NOT in the Metabase table.
#   * Amendment side: Metabase sums liability_adjustment over ALL amendments.
#     R. Gulati (5 Oct 2026): use the LATEST amendment only -> we take
#     liability_adjustment from the amendment with the max issue_date. This is a
#     deliberate divergence from Metabase; expect the column to differ at tie-out.
#   * mine.deleted_ind = false.
#
# Source of permit / mine attributes is silver.mine_summary_view (same as Metabase),
# joined to dim_mine on mine_guid for the surrogate key.
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

spark.table("silver.mine_summary_view").createOrReplaceTempView("src_msv")
spark.table("silver.mine").createOrReplaceTempView("src_mine")
spark.table("silver.bond").createOrReplaceTempView("src_bond")
spark.table("silver.bond_permit_xref").createOrReplaceTempView("src_bond_permit_xref")
spark.table("silver.permit_amendment").createOrReplaceTempView("src_permit_amendment")

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

# BUSINESS LOGIC — build fact_permit_bond.

# C/M permits: one row per permit from mine_summary_view, mine not deleted.
spark.sql("""
    SELECT DISTINCT
        msv.permit_id,
        msv.permit_no,
        msv.mine_guid,
        msv.mine_name,
        msv.mine_number,
        msv.mine_region,
        msv.operation_status,
        msv.permit_status_code,
        msv.permittee_name,
        CAST(msv.status_date AS DATE)  AS permit_status_date,
        CAST(msv.issue_date  AS DATE)  AS permit_issue_date
    FROM src_msv msv
    LEFT JOIN src_mine m
        ON m.mine_guid = msv.mine_guid
    WHERE lower(msv.permit_no) NOT LIKE '%p-%'
      AND lower(msv.permit_no) NOT LIKE '%pm-%'
      AND lower(msv.permit_no) NOT LIKE '%g-%'
      AND lower(msv.permit_no) NOT LIKE '%q-%'
      AND lower(msv.permit_no) NOT LIKE '%mx-%'
      AND lower(msv.permit_no) NOT LIKE '%cx-%'
      AND (m.deleted_ind = false OR m.deleted_ind IS NULL)
""").createOrReplaceTempView("cm_permits")

# Active bonds, summed per permit (Metabase: bond_status_code = 'ACT').
spark.sql("""
    SELECT
        x.permit_id,
        SUM(b.amount)      AS active_bond_amount,
        COUNT(b.bond_id)   AS active_bond_count,
        MAX(b.issue_date)  AS latest_bond_issue_date
    FROM src_bond_permit_xref x
    JOIN src_bond b
        ON b.bond_id = x.bond_id
    WHERE b.bond_status_code = 'ACT'
    GROUP BY x.permit_id
""").createOrReplaceTempView("active_bonds")

# Latest amendment per permit (Raj: liability from the latest amendment, not the sum).
spark.sql("""
    SELECT permit_id, issue_date, liability_adjustment, permit_amendment_type_code
    FROM (
        SELECT pa.*,
               ROW_NUMBER() OVER (PARTITION BY pa.permit_id
                                  ORDER BY pa.issue_date DESC, pa.permit_amendment_id DESC) AS rn
        FROM src_permit_amendment pa
        WHERE pa.issue_date IS NOT NULL
    ) t
    WHERE rn = 1
""").createOrReplaceTempView("latest_amendment")

# Sum over all amendments, kept as a second column so we can still tie out to Metabase.
spark.sql("""
    SELECT permit_id,
           SUM(liability_adjustment) AS liability_adjustment_total,
           COUNT(*)                  AS amendment_count
    FROM src_permit_amendment
    GROUP BY permit_id
""").createOrReplaceTempView("amendment_totals")

df = spark.sql("""
    SELECT
        p.permit_id,
        p.permit_no,

        -- Surrogate keys
        dm.Mine_SK,
        idd.Date_SK                                   AS Permit_Issue_Date_SK,

        -- Permit / mine attributes (denormalised for the drill table)
        p.mine_guid,
        p.mine_name,
        p.mine_number,
        p.mine_region,
        p.operation_status,
        p.permit_status_code,
        CASE WHEN p.permit_status_code = 'O' THEN 'Open'
             WHEN p.permit_status_code = 'C' THEN 'Closed'
             ELSE p.permit_status_code END            AS permit_status,
        p.permittee_name,
        p.permit_status_date,
        p.permit_issue_date,

        -- Bond facts (active only)
        ab.active_bond_amount,
        ab.active_bond_count,
        CAST(ab.latest_bond_issue_date AS DATE)       AS latest_bond_issue_date,
        CASE WHEN ab.permit_id IS NOT NULL THEN 1 ELSE 0 END AS has_active_bond,

        -- Amendment facts
        CAST(la.issue_date AS DATE)                   AS latest_amendment_date,
        la.liability_adjustment                       AS latest_liability_adjustment,
        la.permit_amendment_type_code                 AS latest_amendment_type_code,
        at.liability_adjustment_total,
        at.amendment_count

    FROM cm_permits p
    LEFT JOIN active_bonds ab
        ON ab.permit_id = p.permit_id
    LEFT JOIN latest_amendment la
        ON la.permit_id = p.permit_id
    LEFT JOIN amendment_totals at
        ON at.permit_id = p.permit_id
    LEFT JOIN gold_dim_mine dm
        ON dm.mine_guid = p.mine_guid
        AND dm.dl_iscurrent = 1
    LEFT JOIN gold_dim_date idd
        ON idd.full_date = p.permit_issue_date
""")
print("built dataframe:", df.count(), "rows,", len(df.columns), "cols")
# has_active_bond = 1 rows reproduce the Metabase table (96 permits on 2 Oct 2026).
# Rows with has_active_bond = 0 are kept so the report can show them if Raj wants;
# default the report filter to has_active_bond = 1 to match Metabase.

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

(df.write.format("delta").mode("overwrite")
   .option("overwriteSchema", "true").saveAsTable(TARGET_TABLE))
print("wrote", df.count(), "rows to", TARGET_TABLE)

# Tie-out: Metabase 2868 returned 96 rows on 2 Oct 2026 (active bond, C/M permits).
spark.sql(f"""
    SELECT has_active_bond, COUNT(*) AS permits, SUM(active_bond_amount) AS bond_amount
    FROM {TARGET_TABLE}
    GROUP BY has_active_bond
""").show()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
