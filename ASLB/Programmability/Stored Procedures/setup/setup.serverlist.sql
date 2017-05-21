CREATE PROCEDURE [setup].[serverlist]
AS
BEGIN
DECLARE @ServerList NVARCHAR(MAX);
SELECT @ServerList = STUFF(
(
    SELECT '|' + [vs].[server_name_fqdn] + ';' + [vs].[database_name]
    FROM [setup].[v_services] AS [vs]
    GROUP BY [vs].[server_name_fqdn],
        [vs].[database_name]
    FOR XML PATH(''), TYPE
).[value]('.', 'NVARCHAR(MAX)'),
                              1,
                              1,
                              ''
                          );
SELECT @ServerList;

END