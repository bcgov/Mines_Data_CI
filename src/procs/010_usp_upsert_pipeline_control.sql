-- =============================================================================
-- src/procs/010_usp_upsert_pipeline_control.sql
-- Idempotent: CREATE OR ALTER — safe to deploy repeatedly.
-- Config upsert for app.pipeline_control. Runtime watermark columns
-- (from_date / to_date / last_watermark) are only seeded on first insert and
-- never overwritten by subsequent config refreshes.
-- =============================================================================
CREATE OR ALTER   PROCEDURE [app].[usp_upsert_pipeline_control]
    @pipeline_name VARCHAR(200),
    @source_system VARCHAR(100),
    @source_entity VARCHAR(200),
    @source_connection_string VARCHAR(500) = NULL,
    @key_vault_url VARCHAR(500) = NULL,
    @target_schema VARCHAR(50),
    @target_table VARCHAR(200),
    @source_query_template VARCHAR(MAX) = NULL,
    @from_date DATETIME2(6) = NULL,
    @to_date DATETIME2(6) = NULL,
    @watermark_column VARCHAR(200) = NULL,
    @last_watermark VARCHAR(500) = NULL,
    @load_type VARCHAR(20) = 'INCREMENTAL',
    @load_frequency VARCHAR(50) = NULL,
    @priority INT = 100,
    @dependency_on VARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- -------------------------------------------------------------------------
    -- If the record already exists → UPDATE it in place.
    -- Only config columns are updated; runtime watermark columns (from_date,
    -- to_date, last_watermark) are left untouched so pipeline progress is
    -- never reset by a config refresh.
    -- -------------------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM [app].[pipeline_control]
        WHERE [source_system] = @source_system
          AND [source_entity] = @source_entity
          AND [target_schema] = @target_schema
          AND [target_table]  = @target_table
          AND [is_active]     = 1
    )
    BEGIN
        UPDATE [app].[pipeline_control]
        SET
            [pipeline_name]           = @pipeline_name,
            [source_connection_string]= @source_connection_string,
            [key_vault_url]           = @key_vault_url,
            [source_query_template]   = @source_query_template,
            [watermark_column]        = @watermark_column,
            [load_type]               = @load_type,
            [load_frequency]          = @load_frequency,
            [priority]                = @priority,
            [dependency_on]           = @dependency_on,
            -- from_date / to_date / last_watermark are intentionally NOT updated
            -- here; those are runtime fields managed by the pipeline Log_Success
            -- step. Passing @from_date / @to_date to this SP is only used on
            -- first insert (seeding). Subsequent SP calls must never overwrite
            -- the window that the pipeline has already advanced.
            [modified_date]           = CAST(SYSUTCDATETIME() AS DATETIME2(6)),
            [modified_by]             = SUSER_SNAME()
        WHERE [source_system] = @source_system
          AND [source_entity] = @source_entity
          AND [target_schema] = @target_schema
          AND [target_table]  = @target_table
          AND [is_active]     = 1;

        PRINT CONCAT(
            'Updated pipeline_control record: ', @pipeline_name,
            ' | entity: ', @source_entity
        );
    END
    ELSE
    -- -------------------------------------------------------------------------
    -- Record does not exist → INSERT for the first time, seeding the
    -- from_date / to_date / last_watermark from the @params.
    -- -------------------------------------------------------------------------
    BEGIN
        INSERT INTO [app].[pipeline_control] (
            [pipeline_name],
            [source_system],
            [source_entity],
            [source_connection_string],
            [key_vault_url],
            [target_schema],
            [target_table],
            [source_query_template],
            [from_date],
            [to_date],
            [watermark_column],
            [last_watermark],
            [load_type],
            [is_active],
            [load_frequency],
            [priority],
            [dependency_on],
            [last_run_status],
            [last_run_date],
            [version_number],
            [row_hash],
            [created_date],
            [created_by],
            [modified_date],
            [modified_by]
        )
        VALUES (
            @pipeline_name,
            @source_system,
            @source_entity,
            @source_connection_string,
            @key_vault_url,
            @target_schema,
            @target_table,
            @source_query_template,
            @from_date,         -- seed value only; pipeline owns this after first run
            @to_date,           -- seed value only; pipeline owns this after first run
            @watermark_column,
            @last_watermark,    -- seed value only; pipeline owns this after first run
            @load_type,
            1,                  -- is_active
            @load_frequency,
            @priority,
            @dependency_on,
            NULL,               -- last_run_status
            NULL,               -- last_run_date
            1,                  -- version_number (always 1; no versioning)
            CONVERT(VARCHAR(64), HASHBYTES('SHA2_256',
                CONCAT(
                    ISNULL(@source_system, ''), '|',
                    ISNULL(@source_entity, ''), '|',
                    ISNULL(@source_connection_string, ''), '|',
                    ISNULL(@target_schema, ''), '|',
                    ISNULL(@target_table, ''), '|',
                    ISNULL(@source_query_template, ''), '|',
                    ISNULL(@load_type, ''), '|',
                    ISNULL(@watermark_column, '')
                )
            ), 2),
            CAST(SYSUTCDATETIME() AS DATETIME2(6)),
            SUSER_SNAME(),
            CAST(SYSUTCDATETIME() AS DATETIME2(6)),
            SUSER_SNAME()
        );

        PRINT CONCAT(
            'Inserted pipeline_control record (first time): ', @pipeline_name,
            ' | entity: ', @source_entity
        );
    END
END;
GO
