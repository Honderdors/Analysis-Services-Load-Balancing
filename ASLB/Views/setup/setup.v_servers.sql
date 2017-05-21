CREATE VIEW [setup].[v_servers]
AS
SELECT [s].[server_id],
    [s].[server_name],
    [s].[server_name] + '.' + [sd].[domain_name] AS [server_name_fqdn],
    [s].[server_enabled],
    CASE
        WHEN [server_iis_enabled] = 1 THEN
            REPLACE([ut].[url],
                       '<server>',
                       [s].[server_name] + '.' + [sd].[domain_name]
                   )
        ELSE
            [s].[server_name] + '.' + [sd].[domain_name]
    END AS [url]
FROM [setup].[servers] AS [s]
    INNER JOIN [setup].[server_domains] AS [sd]
        ON [sd].[domain_id] = [s].[domain_id]
    INNER JOIN [setup].[url_templates] AS [ut]
        ON [ut].[url_id] = [s].[url_id];