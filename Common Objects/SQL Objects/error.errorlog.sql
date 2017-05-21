CREATE TABLE [error].[errorlog] (
    [Id]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [EventTime] DATETIME2 (7)  NOT NULL,
    [Priority]  NVARCHAR (100) NOT NULL,
    [Component] NVARCHAR (100) NOT NULL,
    [Errormsg]  XML            NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

