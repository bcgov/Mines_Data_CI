-- =============================================================================
-- warehouse_init.sql
-- Initializes the Fabric Warehouse with medallion schemas and app control
-- objects.
--
-- Idempotent: safe to run any number of times.
--   * Schemas / tables:  IF NOT EXISTS guards
--   * Schema drift:      sys.columns existence checks + ALTER TABLE ADD guards
--                        (COL_LENGTH is not supported in Fabric Warehouse),
--                        so warehouses created from an older version of this
--                        script converge to the current shape without drops.
--
-- Fabric Warehouse notes (why this file looks different from classic SQL):
--   * No DEFAULT or CHECK constraints — all values are supplied explicitly by
--     the stored procedures in src/procs/ and the seed inserts below.
--   * datetime2 is used at precision (6).
--   * DDL matches what is deployed in the live warehouse (varchar, bigint
--     identity, no enforced constraints).
--
-- Column types (varchar vs nvarchar, int vs bigint) are never altered here.
-- =============================================================================

-- =============================================================================
-- SCHEMAS
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
    EXEC('CREATE SCHEMA [bronze]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA [silver]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA [gold]');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'app')
    EXEC('CREATE SCHEMA [app]');
GO

-- =============================================================================
-- APP SCHEMA: CONTROL TABLE
--
-- One row per (source_system, source_entity, target_schema, target_table).
-- Rows are managed exclusively through app.usp_upsert_pipeline_control so a
-- config refresh can never reset the runtime watermark columns (from_date,
-- to_date, last_watermark) that the pipeline advances via app.usp_pipeline_log.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control'
)
BEGIN
    CREATE TABLE [app].[pipeline_control] (

        -- ── Identity ────────────────────────────────────────────────────────
        [control_id]               BIGINT          IDENTITY NOT NULL,
        [pipeline_name]            VARCHAR(200)    NOT NULL,
        [source_system]            VARCHAR(100)    NOT NULL,
        [source_entity]            VARCHAR(200)    NOT NULL,   -- table / endpoint / file pattern

        -- ── Source connectivity ─────────────────────────────────────────────
        [source_connection_string] VARCHAR(500)    NULL,
        [key_vault_url]            VARCHAR(500)    NULL,

        -- ── Target ──────────────────────────────────────────────────────────
        [target_schema]            VARCHAR(50)     NOT NULL,
        [target_table]             VARCHAR(200)    NOT NULL,

        -- ── Source query template ───────────────────────────────────────────
        -- Full query template executed by the pipeline. Uses the literal
        -- tokens @from_date and @to_date as placeholders which the pipeline
        -- substitutes at runtime from the from_date / to_date columns.
        [source_query_template]    VARCHAR(MAX)    NULL,

        -- ── Incremental filter window (runtime — owned by the pipeline) ─────
        [from_date]                DATETIME2(6)    NULL,       -- inclusive lower bound (@from_date)
        [to_date]                  DATETIME2(6)    NULL,       -- exclusive upper bound (@to_date)

        -- ── Watermark tracking (runtime — owned by the pipeline) ────────────
        [watermark_column]         VARCHAR(200)    NULL,       -- source column driving the window
        [last_watermark]           VARCHAR(500)    NULL,       -- last committed high-watermark value

        -- ── Load behaviour ──────────────────────────────────────────────────
        [load_type]                VARCHAR(20)     NOT NULL,   -- FULL | INCREMENTAL | CDC
        [is_active]                BIT             NOT NULL,
        [load_frequency]           VARCHAR(50)     NULL,       -- DAILY | HOURLY | ON_DEMAND
        [priority]                 INT             NOT NULL,   -- lower = runs first
        [dependency_on]            VARCHAR(200)    NULL,       -- pipeline_name this must wait for

        -- ── Last run outcome (written back by app.usp_pipeline_log) ─────────
        [last_run_status]          VARCHAR(20)     NULL,       -- SUCCEEDED | FAILED
        [last_run_date]            DATETIME2(6)    NULL,       -- UTC timestamp of last completed run

        -- ── Versioning / change detection ───────────────────────────────────
        [version_number]           INT             NOT NULL,
        [row_hash]                 VARCHAR(64)     NULL,

        -- ── Audit ───────────────────────────────────────────────────────────
        [created_date]             DATETIME2(6)    NOT NULL,
        [created_by]               VARCHAR(200)    NOT NULL,
        [modified_date]            DATETIME2(6)    NOT NULL,
        [modified_by]              VARCHAR(200)    NOT NULL,

        -- ── Target key metadata ─────────────────────────────────────────────
        [primary_key]              VARCHAR(200)    NULL        -- PK column(s) of the target table
    );
END;
GO

-- ── Drift guards: columns added after the first release ──────────────────────
-- New columns are added as NULL so this converges on any existing table.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'source_connection_string'
)
    ALTER TABLE [app].[pipeline_control] ADD [source_connection_string] VARCHAR(500) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'key_vault_url'
)
    ALTER TABLE [app].[pipeline_control] ADD [key_vault_url] VARCHAR(500) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'source_query_template'
)
    ALTER TABLE [app].[pipeline_control] ADD [source_query_template] VARCHAR(MAX) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'version_number'
)
    ALTER TABLE [app].[pipeline_control] ADD [version_number] INT NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'row_hash'
)
    ALTER TABLE [app].[pipeline_control] ADD [row_hash] VARCHAR(64) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_control' AND c.name = 'primary_key'
)
    ALTER TABLE [app].[pipeline_control] ADD [primary_key] VARCHAR(200) NULL;
GO

-- =============================================================================
-- APP SCHEMA: LOGGING TABLE
--
-- One row per pipeline activity execution, written via app.usp_pipeline_log
-- ('START' inserts/rearms a RUNNING row keyed on activity_run_id; 'END' closes
-- it and conditionally advances the control-table watermark).
-- Status values written by the proc: RUNNING | SUCCEEDED | FAILED.
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_log'
)
BEGIN
    CREATE TABLE [app].[pipeline_log] (
        [log_id]              BIGINT         IDENTITY NOT NULL,
        [run_id]              VARCHAR(100)   NULL,              -- pipeline run ID
        [activity_run_id]     VARCHAR(100)   NOT NULL,          -- activity run ID (idempotency key)
        [pipeline_name]       VARCHAR(200)   NULL,
        [source_entity]       VARCHAR(200)   NULL,
        [target_schema]       VARCHAR(50)    NULL,
        [target_table]        VARCHAR(200)   NULL,
        [status]              VARCHAR(20)    NOT NULL,          -- RUNNING | SUCCEEDED | FAILED
        [rows_read]           BIGINT         NULL,
        [rows_written]        BIGINT         NULL,
        [rows_skipped]        BIGINT         NULL,
        [from_date]           DATETIME2(6)   NULL,              -- filter window used for this run
        [to_date]             DATETIME2(6)   NULL,
        [watermark_start]     VARCHAR(500)   NULL,              -- watermark at run start
        [watermark_end]       VARCHAR(500)   NULL,              -- watermark at run end
        [error_message]       VARCHAR(MAX)   NULL,
        [error_code]          VARCHAR(100)   NULL,
        [start_time]          DATETIME2(6)   NOT NULL,
        [end_time]            DATETIME2(6)   NULL,
        [environment]         VARCHAR(20)    NOT NULL,
        [triggered_by]        VARCHAR(200)   NULL,
        [created_date]        DATETIME2(6)   NOT NULL
    );
END;
GO

-- ── Drift guards ──────────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_log' AND c.name = 'activity_run_id'
)
    ALTER TABLE [app].[pipeline_log] ADD [activity_run_id] VARCHAR(100) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_log' AND c.name = 'error_code'
)
    ALTER TABLE [app].[pipeline_log] ADD [error_code] VARCHAR(100) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_log' AND c.name = 'environment'
)
    ALTER TABLE [app].[pipeline_log] ADD [environment] VARCHAR(20) NULL;
GO
IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    JOIN sys.tables t  ON c.object_id = t.object_id
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'pipeline_log' AND c.name = 'triggered_by'
)
    ALTER TABLE [app].[pipeline_log] ADD [triggered_by] VARCHAR(200) NULL;
GO

-- =============================================================================
-- APP SCHEMA: CONFIGURATION TABLE
-- Key-value store for environment and runtime configuration
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'config'
)
BEGIN
    CREATE TABLE [app].[config] (
        [config_id]       INT            IDENTITY NOT NULL,
        [config_key]      VARCHAR(200)   NOT NULL,
        [config_value]    VARCHAR(MAX)   NOT NULL,
        [config_group]    VARCHAR(100)   NOT NULL,
        [environment]     VARCHAR(20)    NOT NULL,          -- 'ALL' or a specific env
        [description]     VARCHAR(500)   NULL,
        [is_secret]       BIT            NOT NULL,
        [is_active]       BIT            NOT NULL,
        [created_date]    DATETIME2(6)   NOT NULL,
        [created_by]      VARCHAR(200)   NOT NULL,
        [modified_date]   DATETIME2(6)   NOT NULL,
        [modified_by]     VARCHAR(200)   NOT NULL
    );
END;
GO

-- =============================================================================
-- APP SCHEMA: ERROR LOG TABLE
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'error_log'
)
BEGIN
    CREATE TABLE [app].[error_log] (
        [error_id]          BIGINT         IDENTITY NOT NULL,
        [log_id]            BIGINT         NULL,
        [run_id]            VARCHAR(100)   NULL,
        [pipeline_name]     VARCHAR(200)   NULL,
        [error_number]      INT            NULL,
        [error_severity]    INT            NULL,
        [error_state]       INT            NULL,
        [error_procedure]   VARCHAR(200)   NULL,
        [error_line]        INT            NULL,
        [error_message]     VARCHAR(MAX)   NOT NULL,
        [error_context]     VARCHAR(MAX)   NULL,
        [stack_trace]       VARCHAR(MAX)   NULL,
        [created_date]      DATETIME2(6)   NOT NULL
    );
END;
GO

-- =============================================================================
-- APP SCHEMA: SCHEMA REGISTRY
-- =============================================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'app' AND t.name = 'schema_registry'
)
BEGIN
    CREATE TABLE [app].[schema_registry] (
        [registry_id]     INT            IDENTITY NOT NULL,
        [schema_name]     VARCHAR(50)    NOT NULL,
        [layer]           VARCHAR(50)    NOT NULL,
        [description]     VARCHAR(500)   NULL,
        [owner]           VARCHAR(200)   NULL,
        [created_date]    DATETIME2(6)   NOT NULL
    );
END;
GO

-- ── Seed the registry (guarded per row) ──────────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM [app].[schema_registry] WHERE [schema_name] = 'bronze')
    INSERT INTO [app].[schema_registry] ([schema_name], [layer], [description], [created_date])
    VALUES ('bronze', 'RAW', 'Raw ingested data - no transformations applied', CAST(SYSUTCDATETIME() AS DATETIME2(6)));
GO
IF NOT EXISTS (SELECT 1 FROM [app].[schema_registry] WHERE [schema_name] = 'silver')
    INSERT INTO [app].[schema_registry] ([schema_name], [layer], [description], [created_date])
    VALUES ('silver', 'CLEANSED', 'Cleansed and conformed data - business rules applied', CAST(SYSUTCDATETIME() AS DATETIME2(6)));
GO
IF NOT EXISTS (SELECT 1 FROM [app].[schema_registry] WHERE [schema_name] = 'gold')
    INSERT INTO [app].[schema_registry] ([schema_name], [layer], [description], [created_date])
    VALUES ('gold', 'CURATED', 'Curated aggregates and star schema models for reporting', CAST(SYSUTCDATETIME() AS DATETIME2(6)));
GO
IF NOT EXISTS (SELECT 1 FROM [app].[schema_registry] WHERE [schema_name] = 'app')
    INSERT INTO [app].[schema_registry] ([schema_name], [layer], [description], [created_date])
    VALUES ('app', 'APP', 'Application control objects - logging, config, orchestration', CAST(SYSUTCDATETIME() AS DATETIME2(6)));
GO

-- =============================================================================
-- SEED DEFAULT CONFIGURATION VALUES (guarded per key)
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM [app].[config] WHERE [config_key] = 'retention_days_bronze' AND [environment] = 'ALL')
    INSERT INTO [app].[config] ([config_key], [config_value], [config_group], [environment], [description], [is_secret], [is_active], [created_date], [created_by], [modified_date], [modified_by])
    VALUES ('retention_days_bronze', '90', 'RETENTION', 'ALL', 'Days to retain data in bronze layer', 0, 1, CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME(), CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME());
GO
IF NOT EXISTS (SELECT 1 FROM [app].[config] WHERE [config_key] = 'retention_days_silver' AND [environment] = 'ALL')
    INSERT INTO [app].[config] ([config_key], [config_value], [config_group], [environment], [description], [is_secret], [is_active], [created_date], [created_by], [modified_date], [modified_by])
    VALUES ('retention_days_silver', '365', 'RETENTION', 'ALL', 'Days to retain data in silver layer', 0, 1, CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME(), CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME());
GO
IF NOT EXISTS (SELECT 1 FROM [app].[config] WHERE [config_key] = 'retention_days_gold' AND [environment] = 'ALL')
    INSERT INTO [app].[config] ([config_key], [config_value], [config_group], [environment], [description], [is_secret], [is_active], [created_date], [created_by], [modified_date], [modified_by])
    VALUES ('retention_days_gold', '730', 'RETENTION', 'ALL', 'Days to retain data in gold layer', 0, 1, CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME(), CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME());
GO
IF NOT EXISTS (SELECT 1 FROM [app].[config] WHERE [config_key] = 'max_retry_attempts' AND [environment] = 'ALL')
    INSERT INTO [app].[config] ([config_key], [config_value], [config_group], [environment], [description], [is_secret], [is_active], [created_date], [created_by], [modified_date], [modified_by])
    VALUES ('max_retry_attempts', '3', 'ORCHESTRATION', 'ALL', 'Maximum pipeline retry attempts on failure', 0, 1, CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME(), CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME());
GO
IF NOT EXISTS (SELECT 1 FROM [app].[config] WHERE [config_key] = 'alert_on_failure' AND [environment] = 'ALL')
    INSERT INTO [app].[config] ([config_key], [config_value], [config_group], [environment], [description], [is_secret], [is_active], [created_date], [created_by], [modified_date], [modified_by])
    VALUES ('alert_on_failure', 'true', 'ALERTING', 'ALL', 'Send alert notification on pipeline failure', 0, 1, CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME(), CAST(SYSUTCDATETIME() AS DATETIME2(6)), SUSER_SNAME());
GO

-- =============================================================================
-- DONE — report object counts per schema
-- =============================================================================

SELECT
    s.name          AS schema_name,
    COUNT(t.name)   AS table_count
FROM sys.schemas s
LEFT JOIN sys.tables t ON t.schema_id = s.schema_id
WHERE s.name IN ('bronze', 'silver', 'gold', 'app')
GROUP BY s.name;
GO