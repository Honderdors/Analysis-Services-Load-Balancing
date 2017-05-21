CREATE TABLE [setup].[countermappings]
(
	[countermapping_id] INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	[categoryname] NVARCHAR(200) NOT NULL DEFAULT (''),
	[countername] NVARCHAR(200) NOT NULL DEFAULT (''),
	[instancename] NVARCHAR(200) NOT NULL DEFAULT (''), 
	[app_servers_column] sysname NOT NULL DEFAULT ('')
)
