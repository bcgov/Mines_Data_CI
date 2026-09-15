CREATE TABLE [app].[error_log] (
    [error_id]        BIGINT        IDENTITY NOT NULL,
    [log_id]          BIGINT        NULL,
    [run_id]          VARCHAR (100) NULL,
    [pipeline_name]   VARCHAR (200) NULL,
    [error_number]    INT           NULL,
    [error_severity]  INT           NULL,
    [error_state]     INT           NULL,
    [error_procedure] VARCHAR (200) NULL,
    [error_line]      INT           NULL,
    [error_message]   VARCHAR (MAX) NOT NULL,
    [error_context]   VARCHAR (MAX) NULL,
    [stack_trace]     VARCHAR (MAX) NULL,
    [created_date]    DATETIME2 (6) NOT NULL
);


GO