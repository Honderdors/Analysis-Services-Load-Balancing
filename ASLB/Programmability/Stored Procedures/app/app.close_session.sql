CREATE PROCEDURE [app].[close_session]
    @ServiceName NVARCHAR(100) = NULL, /*needed to find targeted service, if Not set use default from properties*/
    @DatabaseName NVARCHAR(100),       /*needed to find database to query*/
    @UserName NVARCHAR(100),
    @IPAddress NVARCHAR(100),
    @Params NVARCHAR(100)
WITH EXECUTE AS OWNER
AS
/*===============================================================================================
|	[close_session]
|	Created By Raymond Honderdors
|	
|	close ASLB session Proc
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
            @endpoint_id INT,
            @URL NVARCHAR(1000);
        IF EXISTS
        (
            SELECT TOP 1
                1
            FROM [app].[sessions] AS [s]
            WHERE [s].[UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params
        )
        BEGIN
            SELECT @connection_id = [connection_id],
                @service_id = [service_id],
                @server_id = [server_id],
                @datebase_id = [datebase_id],
                @URL = [url]
            FROM [app].[sessions] AS [s]
            WHERE [s].[UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params;
            BEGIN TRAN;
            INSERT INTO [log].[sessions]
            SELECT *,GETUTCDATE()
            FROM [app].[sessions]
            WHERE [connection_id] = @connection_id
                  AND [UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params;
            DELETE FROM [app].[sessions]
            WHERE [connection_id] = @connection_id
                  AND [UserName] = @UserName
                  AND [IPAddress] = @IPAddress
                  AND [Params] = @Params;
            COMMIT TRAN;

        END;
    END TRY
    BEGIN CATCH
        --SET @URL = '';
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
                --@loginame AS [ASLB/LoginName],
                @ServiceName AS [ASLB/ServiceName],
                @DatabaseName AS [ASLB/DatabaseName],
                --@hostname AS [ASLB/Request/HostName],
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

END;
