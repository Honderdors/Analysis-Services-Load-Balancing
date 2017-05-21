CREATE TABLE [setup].[service_server_database]
(
/*==========================================================================
=   connection table between service / server / database
==========================================================================*/
	[service_id] INT NOT NULL,
	[server_id] INT NOT NULL,
	[datebase_id] INT NOT NULL, 
    CONSTRAINT [PK_service_server_database] PRIMARY KEY ([service_id], [server_id], [datebase_id])
)
