CREATE TABLE [app].[pipeline_control] (
    [control_id]               BIGINT        IDENTITY NOT NULL,
    [pipeline_name]            VARCHAR (200) NOT NULL,
    [source_system]            VARCHAR (100) NOT NULL,
    [source_entity]            VARCHAR (200) NOT NULL,
    [source_connection_string] VARCHAR (500) NULL,
    [key_vault_url]            VARCHAR (500) NULL,
    [target_schema]            VARCHAR (50)  NOT NULL,
    [target_table]             VARCHAR (200) NOT NULL,
    [source_query_template]    VARCHAR (MAX) NULL,
    [from_date]                DATETIME2 (6) NULL,
    [to_date]                  DATETIME2 (6) NULL,
    [watermark_column]         VARCHAR (200) NULL,
    [last_watermark]           VARCHAR (500) NULL,
    [load_type]                VARCHAR (20)  NOT NULL,
    [is_active]                BIT           NOT NULL,
    [load_frequency]           VARCHAR (50)  NULL,
    [priority]                 INT           NOT NULL,
    [dependency_on]            VARCHAR (200) NULL,
    [last_run_status]          VARCHAR (20)  NULL,
    [last_run_date]            DATETIME2 (6) NULL,
    [version_number]           INT           NOT NULL,
    [row_hash]                 VARCHAR (64)  NULL,
    [created_date]             DATETIME2 (6) NOT NULL,
    [created_by]               VARCHAR (200) NOT NULL,
    [modified_date]            DATETIME2 (6) NOT NULL,
    [modified_by]              VARCHAR (200) NOT NULL,
    [primary_key]              VARCHAR (200) NULL
);


GO