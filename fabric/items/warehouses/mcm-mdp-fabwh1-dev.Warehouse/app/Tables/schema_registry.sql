CREATE TABLE [app].[schema_registry] (
    [registry_id]  BIGINT        IDENTITY NOT NULL,
    [schema_name]  VARCHAR (50)  NOT NULL,
    [layer]        VARCHAR (50)  NOT NULL,
    [description]  VARCHAR (500) NULL,
    [owner]        VARCHAR (200) NULL,
    [created_date] DATETIME2 (6) NOT NULL
);


GO