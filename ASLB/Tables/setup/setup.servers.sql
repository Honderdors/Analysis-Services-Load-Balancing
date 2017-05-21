CREATE TABLE [setup].[servers]
(
/*==========================================================================
=   server setup table
==========================================================================*/
	[server_id] INT NOT NULL PRIMARY KEY /*server indentity number*/,
	[server_name] NVARCHAR(1000) NOT NULL /*server net name*/,
	[server_enabled] BIT DEFAULT(0) /*disabled by default*/,
	[domain_id] INT NOT NULL /*from lookup*/, 
	[url_id] INT NOT NULL /*from lookup*/, 
    [server_iis_enabled] BIT NULL DEFAULT 0
)
