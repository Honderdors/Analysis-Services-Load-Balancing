CREATE PROCEDURE [app].[get_session]
    @ServiceName NVARCHAR(100) = NULL, /*needed to find targeted service, if Not set use default from properties*/
    @DatabaseName NVARCHAR(100),       /*needed to find database to query*/
    @UserName NVARCHAR(100),
    @IPAddress NVARCHAR(100),
    @Params NVARCHAR(100),
    @URL NVARCHAR(1000) OUTPUT,
    @UseTCPIP BIT = 0                  /*type of string to retun as url*/

WITH EXECUTE AS OWNER
AS
/*===============================================================================================
|	[get_session]
|	Created By Raymond Honderdors
|	
|	get ASLB session Proc
|	test    http://ilcd01.eyeblaster.com:52334/CRB/Analytics4
===============================================================================================*/

/*===============================================================================================
	Change Log
	2017-04-05		Raymond		v1.0.0		Added version control
===============================================================================================*/
BEGIN

    BEGIN TRY
        /*System Level Variables*/
        DECLARE @Default_Service NVARCHAR(100) = 'Default_Service',
            @ASLB_Version NVARCHAR(100) = 'ASLB_Version',
            @Session_TTL NVARCHAR(100) = 'Session_TTL';
        DECLARE @System_version NVARCHAR(100),
            @version NVARCHAR(MAX) = '';
        SELECT @System_version = [setup].[fn_getsystempropertyvalue](@ASLB_Version),
            @Session_TTL = [setup].[fn_getsystempropertyvalue](@Session_TTL);
        /*
================================================================================================
*/
        SET @version = 'v1.0.0';
        /*
================================================================================================
*/

        IF @ServiceName IS NULL
        BEGIN
            SELECT @ServiceName = [setup].[fn_getsystempropertyvalue](@Default_Service);
        END;

        PRINT @System_version + ' @' + CAST(GETUTCDATE() AS NVARCHAR(100)); /*Debug info*/
        PRINT SUSER_SNAME();
        PRINT SUSER_NAME();
        /*Session Level Variables*/
        DECLARE @service_id BIGINT,
            @server_id BIGINT,
            @datebase_id BIGINT,
            @connection_id UNIQUEIDENTIFIER,
            @net_transport NVARCHAR(40),
            @protocol_type NVARCHAR(40),
            @encrypt_option NVARCHAR(40),
            @auth_scheme NVARCHAR(40),
            @client_net_address NVARCHAR(48),
            @client_tcp_port INT,
            @hostname NVARCHAR(128),
            @program_name NVARCHAR(128),
            @nt_domain NVARCHAR(128),
            @nt_username NVARCHAR(128),
            @net_address NVARCHAR(128),
            @loginame NVARCHAR(128),
            @endpoint_id INT;

        /*Get Connection Details*/
        /*Unique ID  of Request*/
        /*@UserName + @IPAddress + @Params*/
        /*System level Params*/
        /*from [sys].[sysprocesses] + [sys].[dm_exec_connections]*/

        /*Get Service ID*/
        SELECT @server_id = [s].[service_id]
        FROM [setup].[service] AS [s]
        WHERE [s].[service_name] = @ServiceName;

        SELECT @connection_id = [dec].[connection_id],
            @net_transport = [dec].[net_transport],
            @protocol_type = [dec].[protocol_type],
            @encrypt_option = [dec].[encrypt_option],
            @auth_scheme = [dec].[auth_scheme],
            @client_net_address = [dec].[client_net_address],
            @client_tcp_port = [dec].[client_tcp_port],
            @hostname = [s].[hostname],
            @program_name = [s].[program_name],
            @nt_domain = [s].[nt_domain],
            @nt_username = [s].[nt_username],
            @net_address = [s].[net_address],
            @loginame = [s].[loginame],
            @endpoint_id = [dec].[endpoint_id]
        FROM [sys].[dm_exec_connections] AS [dec] WITH (NOLOCK)
            INNER JOIN [sys].[sysprocesses] AS [s] WITH (NOLOCK)
                ON [dec].[session_id] = [s].[spid]
        WHERE [dec].[session_id] = @@SPID; /*Get Current Connection Delails*/

        IF @Params = ''
        BEGIN
            SET @Params = @connection_id;
        END;

        IF EXISTS
        (
            SELECT TOP 1
                1
            FROM [app].[sessions] AS [s]
            WHERE [s].[UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params
                  AND [service_id] = @server_id
        )
        BEGIN
            SELECT @connection_id = [connection_id],
                @service_id = [service_id],
                @datebase_id = [datebase_id],
                @URL = [url],
                @server_id = [server_id]
            FROM [app].[sessions] AS [s]
            WHERE [s].[UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params
                  AND [service_id] = @server_id;

            UPDATE [app].[sessions]
            SET [last_request_time] = GETUTCDATE(),
                [request_counter] = [request_counter] + 1
            WHERE [connection_id] = @connection_id
                  AND [UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params
                  AND [server_id] = @server_id;
        END;
        ELSE
        BEGIN

            --PRINT 1;
            /*********************/
            /*Server Load Type 1 */
            /*********************/
            SELECT TOP (1)
                @service_id = [vs].[service_id],
                @server_id = [vs].[server_id],
                @datebase_id = [vs].[datebase_id],
                @URL = CASE
                           WHEN @UseTCPIP = 1 THEN
                               [vs].[server_name_fqdn]
                           ELSE
                               [vs].[url]
                       END
            FROM [setup].[v_services] AS [vs]
                LEFT OUTER JOIN [app].[servers] AS [s]
                    ON [vs].[server_id] = [s].[server_id]
            WHERE [vs].[service_name] = @ServiceName
                  AND [vs].[database_name] = @DatabaseName
                  AND ISNULL([s].[server_offline], 1) = 0
                  AND [vs].[loadbalance_id] = 1 /**Server Load**/
            ORDER BY [s].[server_cpu] ASC,
                [server_memory] ASC,
                [server_connections] ASC,
                [server_load_update_time] ASC,
                [server_last_request_time] ASC;

            /*********************/
            /*Round Robin Type 2 */
            /*********************/
            SELECT TOP (1)
                @service_id = [vs].[service_id],
                @server_id = [vs].[server_id],
                @datebase_id = [vs].[datebase_id],
                @URL = CASE
                           WHEN @UseTCPIP = 1 THEN
                               [vs].[server_name_fqdn]
                           ELSE
                               [vs].[url]
                       END
            FROM [setup].[v_services] AS [vs]
                LEFT OUTER JOIN [app].[servers] AS [s]
                    ON [vs].[server_id] = [s].[server_id]
            WHERE [vs].[service_name] = @ServiceName
                  AND [vs].[database_name] = @DatabaseName
                  AND ISNULL([s].[server_offline], 1) = 0
                  AND [vs].[loadbalance_id] = 2 /**Round Robin**/
            ORDER BY [s].[server_last_request_time] ASC,
                [server_connections] ASC;

            PRINT @connection_id;
            INSERT INTO [app].[sessions]
            VALUES
            (@connection_id,
                @service_id,
                @server_id,
                @datebase_id,
                @UserName,
                @IPAddress,
                @Params,
                @URL,
                @net_transport,
                @protocol_type,
                @encrypt_option,
                @auth_scheme,
                @client_net_address,
                @client_tcp_port,
                @hostname,
                @program_name,
                @nt_domain,
                @nt_username,
                @net_address,
                @loginame,
                @endpoint_id,
                GETUTCDATE(),
                GETUTCDATE(),
                1
            );
        END;

        IF EXISTS
        (
            SELECT TOP (1)
                1
            FROM [app].[servers]
            WHERE [server_id] = @server_id
        )
        BEGIN
            UPDATE [app].[servers]
            SET [server_last_request_time] = GETUTCDATE()
            WHERE [server_id] = @server_id;

        END;
        ELSE
        BEGIN
            INSERT INTO [app].[servers]
            VALUES
            (@server_id, 1, GETUTCDATE(), GETUTCDATE(), NULL, NULL, NULL, NULL, NULL);
        END;

    END TRY
    BEGIN CATCH
        SET @URL = '';
        IF (@@TRANCOUNT > 0)
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorNumber INT;
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
        DECLARE @ErrorLine INT;
        DECLARE @Msg XML;
        DECLARE @ErrorProc NVARCHAR(126);


        SET @ErrorState = CASE
                              WHEN @ErrorState
                                   BETWEEN 1 AND 127 THEN
                                  @ErrorState
                              ELSE
                                  1
                          END;
        SET @ErrorProc = ISNULL(@ErrorProc,
                                   CONVERT(NVARCHAR(126), OBJECT_NAME(@@PROCID))
                               );

        SELECT @ErrorMessage = ERROR_MESSAGE(),
            @ErrorNumber = ERROR_NUMBER(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
            @ErrorLine = ERROR_LINE(),
            @ErrorProc = ERROR_PROCEDURE();
        SET @Msg =
        (
            SELECT GETUTCDATE() AS [EventTime],
                @ErrorProc AS [ObjectName],
                @ErrorNumber AS [Error/Number],
                @ErrorMessage AS [Error/Message],
                @ErrorSeverity AS [Error/Severity],
                @ErrorState AS [Error/State],
                @ErrorLine AS [Error/Line],
                @version AS [Error/Version],
                @System_version AS [ASLB/System_Vesion],
                @loginame AS [ASLB/LoginName],
                @ServiceName AS [ASLB/ServiceName],
                @DatabaseName AS [ASLB/DatabaseName],
                @hostname AS [ASLB/Request/HostName],
                @Params AS [ASLB/Request/Params]
            FOR XML PATH('Event')
        );
        EXEC [error].[sp_errorhandler] @ErrorMessage = @ErrorMessage,
            @ErrorNumber = @ErrorNumber,
            @ErrorSeverity = @ErrorSeverity,
            @ErrorState = @ErrorState,
            @ErrorLine = @ErrorLine,
            @ErrorProc = @ErrorProc,
            @ErrorXML = @Msg;
    END CATCH;

    SELECT @connection_id;
END;