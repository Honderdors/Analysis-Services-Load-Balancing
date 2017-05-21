/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/


--SELECT [$(VisualStudioEdition)]
/**Set up tables**/
/*[setup].[loadbalancetypes]*/
PRINT '[setup].[loadbalancetypes]';
MERGE [setup].[loadbalancetypes] AS [T]
USING
(
    SELECT 1 AS [loadbalance_id],
        N'Server Load' AS [loadbalance_name]
    UNION
    SELECT 2 AS [loadbalance_id],
        N'Round Robin' AS [loadbalance_name]
) AS [S]
ON [T].[loadbalance_id] = [S].[loadbalance_id]
WHEN MATCHED THEN
    UPDATE SET [T].[loadbalance_name] = [S].[loadbalance_name]
WHEN NOT MATCHED THEN
    INSERT VALUES
           ([S].[loadbalance_id], [S].[loadbalance_name]);
GO
/*[setup].[url_templates]*/
PRINT '[setup].[url_templates]';
MERGE [setup].[url_templates] AS [T]
USING
(
    SELECT 1 AS [url_id],
        N'http://<server>/OLAP/msmdpump.dll' AS [url]
) AS [S]
ON [T].[url_id] = [S].[url_id]
WHEN MATCHED THEN
    UPDATE SET [T].[url] = [S].[url]
WHEN NOT MATCHED THEN
    INSERT VALUES
           ([S].[url_id], [S].[url]);
GO
/*[setup].[system_global_variables]*/
PRINT '[setup].[system_global_variables]';
DECLARE @sversion NVARCHAR(100) = 'V1.0.1',
    @VSEdition NVARCHAR(1000);
SELECT @VSEdition = '[$(VisualStudioEdition)]';
MERGE [setup].[system_global_variables] AS [T]
USING
(
    SELECT N'Default_Service' AS [property_name],                              -- property_name - nvarchar(100)
        N'CRB' AS [property_value],                                            -- property_value - nvarchar(4000)
        N'Default Value To Use As System Level Service Name' AS [description], -- description - nvarchar(200)
        GETUTCDATE() AS [property_timestamp],                                  -- property_timestamp - smalldatetime
        SUSER_SNAME() AS [LastUpdateBy],                                       -- LastUpdateBy - nvarchar(1000)
        N'ASLB|Defaults|Service' AS [Property_Path]                            -- Property_Path - nvarchar(max)
    UNION
    SELECT N'ASLB_Version' AS [property_name],           -- property_name - nvarchar(100)
        @sversion AS [property_value],                   -- property_value - nvarchar(4000)
        N'System Level Version Number' AS [description], -- description - nvarchar(200)
        GETUTCDATE() AS [property_timestamp],            -- property_timestamp - smalldatetime
        SUSER_SNAME() AS [LastUpdateBy],                 -- LastUpdateBy - nvarchar(1000)
        N'ASLB|System' AS [Property_Path]                -- Property_Path - nvarchar(max)
    UNION
    SELECT N'Session_TTL' AS [property_name],                -- property_name - nvarchar(100)
        N'10' AS [property_value],                           -- property_value - nvarchar(4000)
        N'Session Time To Live in Minutes' AS [description], -- description - nvarchar(200)
        GETUTCDATE() AS [property_timestamp],                -- property_timestamp - smalldatetime
        SUSER_SNAME() AS [LastUpdateBy],                     -- LastUpdateBy - nvarchar(1000)
        N'ASLB|System' AS [Property_Path]                    -- Property_Path - nvarchar(max)
    UNION
    SELECT N'VisualStudio' AS [property_name],           -- property_name - nvarchar(100)
        @VSEdition AS [property_value],                  -- property_value - nvarchar(4000)
        N'Visual Studio Build Edition' AS [description], -- description - nvarchar(200)
        GETUTCDATE() AS [property_timestamp],            -- property_timestamp - smalldatetime
        SUSER_SNAME() AS [LastUpdateBy],                 -- LastUpdateBy - nvarchar(1000)
        N'ASLB|System' AS [Property_Path]                -- Property_Path - nvarchar(max)
) AS [S]
ON [T].[property_name] = [S].[property_name]
WHEN MATCHED THEN
    UPDATE SET [T].[property_value] = [S].[property_value],
        [T].[description] = [S].[description],
        [T].[Property_Path] = [S].[Property_Path]
WHEN NOT MATCHED THEN
    INSERT VALUES
           ([S].[property_name],
               [S].[property_value],
               [S].[description],
               [S].[property_timestamp],
               [S].[LastUpdateBy],
               [S].[Property_Path]
           );
GO
/*[setup].[countermappings]*/
PRINT '[setup].[countermappings]';
DECLARE @sversion NVARCHAR(100) = 'V1.0.1',
    @VSEdition NVARCHAR(1000);

/*
ASLB:Service;Server;Analytics4
Processor;% Processor Time;_Total
Memory;Available KBytes
MSAS11:Connection;Current connections
*/
MERGE [setup].[countermappings] AS [T]
USING
(
    SELECT N'ASLB:Service' AS [categoryname],    -- categoryname - nvarchar(200)
        N'Server' AS [countername],              -- countername - nvarchar(200)
        N'Analytics4' AS [instancename],         -- instancename - nvarchar(200)
        'server_offline' AS [app_servers_column] -- app_servers_column - sysname
    UNION
    SELECT N'Processor',     -- categoryname - nvarchar(200)
        N'% Processor Time', -- countername - nvarchar(200)
        N'_Total',           -- instancename - nvarchar(200)
        'server_cpu'         -- app_servers_column - sysname
    UNION
    SELECT N'Memory',        -- categoryname - nvarchar(200)
        N'Available KBytes', -- countername - nvarchar(200)
        N'',                 -- instancename - nvarchar(200)
        'server_memory'      -- app_servers_column - sysname
    UNION
    SELECT N'MSAS11:Connection', -- categoryname - nvarchar(200)
        N'Current connections',  -- countername - nvarchar(200)
        N'',                     -- instancename - nvarchar(200)
        'server_connections'     -- app_servers_column - sysname
) AS [S]
ON [T].[categoryname] = [S].[categoryname]
   AND [S].[countername] = [T].[countername]
   AND [S].[instancename] = [T].[instancename]
WHEN MATCHED THEN
    UPDATE SET [T].[app_servers_column] = [S].[app_servers_column]
WHEN NOT MATCHED THEN
    INSERT VALUES
           ([S].[categoryname], [S].[countername], [S].[instancename], [S].[app_servers_column]);