CREATE TABLE [log].[performancecounters]
(
	[performancecounters_id] BIGINT NOT NULL IDENTITY(1,1),
	[collection_id] UNIQUEIDENTIFIER NOT NULL,
	[collection_time] DATETIME2(7) NOT NULL DEFAULT(GETUTCDATE()),
	[categoryname] NVARCHAR(200) NOT NULL DEFAULT (''),
	[countername] NVARCHAR(200) NOT NULL DEFAULT (''),
	[instancename] NVARCHAR(200) NOT NULL DEFAULT (''), 
	[machinename] NVARCHAR(200) NOT NULL  DEFAULT (''), 
    [countervalue] FLOAT NOT NULL DEFAULT 0, 
    CONSTRAINT [PK_performancecounters] PRIMARY KEY ([performancecounters_id])
)
