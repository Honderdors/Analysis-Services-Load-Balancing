CREATE VIEW [setup].[v_services]
AS
SELECT [s].[service_id],
    [s].[service_name],
    [s2].[server_id],
    [s2].[server_name_fqdn],
    [d].[datebase_id],
    [d].[database_name],
    [s2].[url],
    [s].[loadbalance_id]
FROM [setup].[service_server_database] AS [ssd]
    INNER JOIN [setup].[service] AS [s]
        ON [s].[service_id] = [ssd].[service_id]
    INNER JOIN [setup].[v_servers] AS [s2]
        ON [s2].[server_id] = [ssd].[server_id]
    INNER JOIN [setup].[databases] AS [d]
        ON [d].[datebase_id] = [ssd].[datebase_id]
WHERE [s].[service_enabled] = 1
      AND [s2].[server_enabled] = 1
      AND [d].[database_enabled] = 1;
