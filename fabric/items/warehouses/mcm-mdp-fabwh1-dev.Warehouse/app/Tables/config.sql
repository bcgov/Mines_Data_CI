CREATE TABLE [app].[config] (
    [config_id]     BIGINT        IDENTITY NOT NULL,
    [config_key]    VARCHAR (200) NOT NULL,
    [config_value]  VARCHAR (MAX) NOT NULL,
    [config_group]  VARCHAR (100) NOT NULL,
    [environment]   VARCHAR (20)  NOT NULL,
    [description]   VARCHAR (500) NULL,
    [is_secret]     BIT           NOT NULL,
    [is_active]     BIT           NOT NULL,
    [created_date]  DATETIME2 (6) NOT NULL,
    [created_by]    VARCHAR (200) NOT NULL,
    [modified_date] DATETIME2 (6) NOT NULL,
    [modified_by]   VARCHAR (200) NOT NULL
);


GO