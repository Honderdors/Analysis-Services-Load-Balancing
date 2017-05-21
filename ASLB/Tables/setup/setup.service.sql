CREATE TABLE [setup].[service]
(
/*==========================================================================
=   service setup table
==========================================================================*/
	[service_id] INT NOT NULL PRIMARY KEY /*service identity number*/,
	[service_name] NVARCHAR(100) NOT NULL /*service name used on connection*/,
	[service_enabled] BIT DEFAULT(0) /*disabled by default*/,
	[loadbalance_id] int NOT NULL /*from lookup table*/
)
