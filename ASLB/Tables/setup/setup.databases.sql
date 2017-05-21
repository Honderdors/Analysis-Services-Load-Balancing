CREATE TABLE [setup].[databases]
(
/*==========================================================================
=   database setup table
==========================================================================*/
	[datebase_id] INT NOT NULL PRIMARY KEY,
	[database_name] NVARCHAR(100) NOT NULL,
	[database_enabled] BIT DEFAULT(0)
)
