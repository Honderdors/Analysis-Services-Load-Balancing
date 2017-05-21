CREATE PROCEDURE [app].[close_sessions]
WITH EXECUTE AS OWNER
AS
/*===============================================================================================
|	[close_sessions]
|	Created By Raymond Honderdors
|	
|	close ASLB sessions Proc based on TTL
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
            @version NVARCHAR(MAX) = '',
            @Session_TTL_value BIGINT;
        SELECT @System_version = [setup].[fn_getsystempropertyvalue](@ASLB_Version),
            @Session_TTL_value = CAST([setup].[fn_getsystempropertyvalue](@Session_TTL) AS BIGINT);
        /*
================================================================================================
*/
        SET @version = 'v1.0.0';
        /*
================================================================================================
*/
        DECLARE @ServiceName NVARCHAR(100);

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
            @endpoint_id INT,
            @URL NVARCHAR(1000),
            @currentdate DATETIME2(7) = GETUTCDATE();

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

        IF EXISTS
        (
            SELECT TOP (1)
                1
            FROM [app].[sessions] AS [s]
            WHERE [s].[last_request_time] <= DATEADD(MINUTE, -@Session_TTL_value, @currentdate)
        )
        BEGIN
            BEGIN TRAN;
            INSERT INTO [log].[sessions]
            SELECT *,
                @currentdate
            FROM [app].[sessions] AS [s]
            WHERE [s].[last_request_time] <= DATEADD(MINUTE, -@Session_TTL_value, @currentdate);
            DELETE FROM [app].[sessions]
            WHERE [last_request_time] <= DATEADD(MINUTE, -@Session_TTL_value, @currentdate);
            COMMIT TRAN;
        END;
        IF EXISTS
        (
            SELECT TOP (1)
                1
            FROM [app].[sessions] AS [s]
                INNER JOIN [app].[servers] AS [s2]
                    ON [s2].[server_id] = [s].[server_id]
            WHERE [s2].[server_offline] = 1
        )
        BEGIN
            BEGIN TRAN;
            INSERT INTO [log].[sessions]
            SELECT *,
                @currentdate
            FROM [app].[sessions] AS [s]
            WHERE [s].[server_id] IN (SELECT [s].[server_id] FROM app.[servers] AS [s] WHERE [s].[server_offline] =1);
            DELETE FROM [app].[sessions]
            WHERE [server_id] IN (SELECT [s].[server_id] FROM app.[servers] AS [s] WHERE [s].[server_offline] =1);
            COMMIT TRAN;
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
                @hostname AS [ASLB/Request/HostName]
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
END;