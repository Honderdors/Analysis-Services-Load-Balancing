CREATE PROCEDURE [app].[server_load]
    @server_name NVARCHAR(200),
    @categoryname NVARCHAR(200),
    @countername NVARCHAR(200),
    @instancename NVARCHAR(200),
    @countervalue FLOAT
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
        SET NOCOUNT ON;
        PRINT @System_version + ' @' + CAST(GETUTCDATE() AS NVARCHAR(100)); /*Debug info*/
        PRINT SUSER_SNAME();
        PRINT SUSER_NAME();

        DECLARE @server_id BIGINT,
            @SQLCommand NVARCHAR(MAX),
            @SQLTimeColumn NVARCHAR(MAX),
            @appcolumn sysname,
            @ChangeDate DATETIME2(7);
        SELECT @server_id = [server_id]
        FROM [setup].[servers] WITH (NOLOCK)
        WHERE [server_name] = @server_name;

        SET @ChangeDate = GETUTCDATE();

        IF (@categoryname = 'ASLB:Service' AND @countername = 'Server')
        BEGIN
            SELECT @countervalue = CASE
                                       WHEN @countervalue <> 0 THEN
                                           1
                                       ELSE
                                           0
                                   END;
            IF @countervalue = 1
            BEGIN
                SET @SQLTimeColumn = ',[server_offline_time] = GETUTCDATE()';
            END;
            ELSE
            BEGIN
                SET @SQLTimeColumn = ',[server_online_time] = GETUTCDATE()';
            END;
        END;
        ELSE
        BEGIN
            SET @SQLTimeColumn = '';
        END;
        /*[server_load_update_time] = GETUTCDATE()*/
        SET @SQLCommand = 'BEGIN TRY BEGIN TRAN ';
        SET @SQLCommand
            = @SQLCommand + ' UPDATE [app].[servers] SET <COL1>=<COL2> ' + @SQLTimeColumn + ' WHERE [server_id] = '
              + CAST(@server_id AS NVARCHAR(100)) + ' AND ISNULL(<COL1>,0)<>ISNULL(<COL2>,0) ;';
        SET @SQLCommand = @SQLCommand + 'IF (@@ROWCOUNT =1) BEGIN';
        SET @SQLCommand
            = @SQLCommand
              + ' INSERT INTO [log].[servers] SELECT GETUTCDATE(), * FROM [app].[servers] WHERE [server_id] = '
              + CAST(@server_id AS NVARCHAR(100)) + '; END';

        SET @SQLCommand
            = @SQLCommand + ' UPDATE [app].[servers] SET [server_load_update_time] = GETUTCDATE() WHERE [server_id] = '
              + CAST(@server_id AS NVARCHAR(100)) + ';';

        SET @SQLCommand
            = @SQLCommand + ' COMMIT TRAN END TRY BEGIN CATCH IF (@@TRANCOUNT>0) ROLLBACK TRAN; END CATCH;';

        SELECT @appcolumn = [c].[app_servers_column]
        FROM [setup].[countermappings] AS [c]
        WHERE [c].[categoryname] = @categoryname
              AND [c].[countername] = @countername
              AND [c].[instancename] = @instancename
              AND ISNULL([app_servers_column], '') <> '';

        SET @SQLCommand = REPLACE(@SQLCommand, '<COL1>', '[' + @appcolumn + ']');
        SET @SQLCommand = REPLACE(@SQLCommand, '<COL2>', '' + CAST(@countervalue AS NVARCHAR(100)) + '');

        EXEC [sys].[sp_executesql] @SQLCommand;
        EXEC [app].[close_sessions];
    END TRY
    BEGIN CATCH

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
                @System_version AS [ASLB/System_Vesion]
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
    SET NOCOUNT OFF;

END;