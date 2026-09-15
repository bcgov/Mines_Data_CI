CREATE TABLE [app].[pipeline_log] (
    [log_id]          BIGINT        IDENTITY NOT NULL,
    [run_id]          VARCHAR (100) NULL,
    [activity_run_id] VARCHAR (100) NOT NULL,
    [pipeline_name]   VARCHAR (200) NULL,
    [source_entity]   VARCHAR (200) NULL,
    [target_schema]   VARCHAR (50)  NULL,
    [target_table]    VARCHAR (200) NULL,
    [status]          VARCHAR (20)  NOT NULL,
    [rows_read]       BIGINT        NULL,
    [rows_written]    BIGINT        NULL,
    [rows_skipped]    BIGINT        NULL,
    [from_date]       DATETIME2 (6) NULL,
    [to_date]         DATETIME2 (6) NULL,
    [watermark_start] VARCHAR (500) NULL,
    [watermark_end]   VARCHAR (500) NULL,
    [error_message]   VARCHAR (MAX) NULL,
    [error_code]      VARCHAR (100) NULL,
    [start_time]      DATETIME2 (6) NOT NULL,
    [end_time]        DATETIME2 (6) NULL,
    [environment]     VARCHAR (20)  NOT NULL,
    [triggered_by]    VARCHAR (200) NULL,
    [created_date]    DATETIME2 (6) NOT NULL
);


GO