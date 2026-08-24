-- =============================================================================
-- src/procs/020_usp_pipeline_log.sql
-- Idempotent: CREATE OR ALTER — safe to deploy repeatedly.
-- START/END logger for app.pipeline_log. END mode conditionally advances the
-- app.pipeline_control watermark. START is retry-safe (keyed on
-- activity_run_id, so activity retries re-arm the same row instead of
-- duplicating it).
-- =============================================================================
CREATE OR ALTER PROCEDURE [app].[usp_pipeline_log]
    -- ── Mode ─────────────────────────────────────────────────────────────────
    @mode             VARCHAR(10),                  -- 'START' | 'END'

    -- ── Identity (required both modes) ───────────────────────────────────────
    @activity_run_id  VARCHAR(100),

    -- ── START mode ───────────────────────────────────────────────────────────
    @run_id           VARCHAR(100)  = NULL,
    @pipeline_name    VARCHAR(200)  = NULL,
    @source_entity    VARCHAR(200)  = NULL,
    @target_schema    VARCHAR(50)   = NULL,
    @target_table     VARCHAR(200)  = NULL,
    @from_date        DATETIME2(6)  = NULL,
    @to_date          DATETIME2(6)  = NULL,
    @watermark_start  VARCHAR(500)  = NULL,
    @environment      VARCHAR(20)   = NULL,
    @triggered_by     VARCHAR(200)  = NULL,

    -- ── END mode ─────────────────────────────────────────────────────────────
    @control_id       BIGINT        = NULL,
    @status           VARCHAR(20)   = NULL,         -- 'SUCCEEDED' | 'FAILED'
    @rows_read        BIGINT        = NULL,
    @rows_written     BIGINT        = NULL,
    @rows_skipped     BIGINT        = NULL,
    @watermark_end    VARCHAR(500)  = NULL,
    @new_watermark    VARCHAR(500)  = NULL,
    @window_from      DATETIME2(6)  = NULL,
    @window_to        DATETIME2(6)  = NULL,
    @advance          BIT           = 1,
    @error_message    VARCHAR(MAX)  = NULL,
    @error_code       VARCHAR(100)  = NULL,
    @modified_by      VARCHAR(200)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @now  DATETIME2(6) = CAST(SYSUTCDATETIME() AS DATETIME2(6));
    DECLARE @m    VARCHAR(10)  = UPPER(LTRIM(RTRIM(ISNULL(@mode, ''))));
    DECLARE @who  VARCHAR(200) = ISNULL(@modified_by, SUSER_SNAME());

    -- =========================================================================
    -- START: insert a RUNNING row
    -- =========================================================================
    IF @m = 'START'
    BEGIN
        -- Script activities carry retries; re-running START must not duplicate.
        IF EXISTS (
            SELECT 1 FROM [app].[pipeline_log]
            WHERE [activity_run_id] = @activity_run_id
        )
        BEGIN
            UPDATE [app].[pipeline_log]
            SET [status]          = 'RUNNING',
                [start_time]      = @now,
                [end_time]        = NULL,
                [rows_read]       = NULL,
                [rows_written]    = NULL,
                [rows_skipped]    = NULL,
                [watermark_end]   = NULL,
                [error_message]   = NULL,
                [error_code]      = NULL,
                [from_date]       = @from_date,
                [to_date]         = @to_date,
                [watermark_start] = @watermark_start
            WHERE [activity_run_id] = @activity_run_id;
        END
        ELSE
        BEGIN
            INSERT INTO [app].[pipeline_log] (
                [run_id],
                [activity_run_id],
                [pipeline_name],
                [source_entity],
                [target_schema],
                [target_table],
                [status],
                [rows_read],
                [rows_written],
                [rows_skipped],
                [from_date],
                [to_date],
                [watermark_start],
                [watermark_end],
                [error_message],
                [error_code],
                [start_time],
                [end_time],
                [environment],
                [triggered_by],
                [created_date]
            )
            VALUES (
                @run_id,
                @activity_run_id,
                @pipeline_name,
                @source_entity,
                @target_schema,
                @target_table,
                'RUNNING',
                NULL,                   -- rows_read
                NULL,                   -- rows_written
                NULL,                   -- rows_skipped
                @from_date,
                @to_date,
                @watermark_start,
                NULL,                   -- watermark_end
                NULL,                   -- error_message
                NULL,                   -- error_code
                @now,                   -- start_time
                NULL,                   -- end_time
                ISNULL(@environment, 'UNKNOWN'),
                @triggered_by,
                @now
            );
        END

        RETURN;
    END

    -- =========================================================================
    -- END: close the log row, then update control state
    -- =========================================================================
    IF @m = 'END'
    BEGIN
        -- ── 1. Log table ─────────────────────────────────────────────────────
        UPDATE [app].[pipeline_log]
        SET [status]        = ISNULL(@status, 'SUCCEEDED'),
            [rows_read]     = ISNULL(@rows_read,     [rows_read]),
            [rows_written]  = ISNULL(@rows_written,  [rows_written]),
            [rows_skipped]  = ISNULL(@rows_skipped,  [rows_skipped]),
            [watermark_end] = ISNULL(@watermark_end, [watermark_end]),
            [error_message] = @error_message,
            [error_code]    = @error_code,
            [end_time]      = @now
        WHERE [activity_run_id] = @activity_run_id;

        -- ── 2. Control table ─────────────────────────────────────────────────
        IF @control_id IS NOT NULL
        BEGIN
            DECLARE @should_advance BIT = 0;

            IF  @status = 'SUCCEEDED'
            AND ISNULL(@rows_written, 0) > 0
            AND @new_watermark IS NOT NULL
            AND LEN(LTRIM(RTRIM(@new_watermark))) > 0
            AND ISNULL(@advance, 1) = 1
                SET @should_advance = 1;

            IF @should_advance = 1
            BEGIN
                UPDATE [app].[pipeline_control]
                SET [last_run_status] = @status,
                    [last_run_date]   = @now,
                    [last_watermark]  = @new_watermark,
                    [from_date]       = ISNULL(@window_from, [from_date]),
                    [to_date]         = ISNULL(@window_to,   [to_date]),
                    [modified_date]   = @now,
                    [modified_by]     = @who
                WHERE [control_id] = @control_id;
            END
            ELSE
            BEGIN
                UPDATE [app].[pipeline_control]
                SET [last_run_status] = ISNULL(@status, [last_run_status]),
                    [last_run_date]   = @now,
                    [modified_date]   = @now,
                    [modified_by]     = @who
                WHERE [control_id] = @control_id;
            END
        END

        RETURN;
    END

    -- =========================================================================
    -- Unknown mode: fail loudly rather than silently no-op
    -- =========================================================================
    ;THROW 50001, 'usp_pipeline_log: @mode must be START or END.', 1;
END;
GO
