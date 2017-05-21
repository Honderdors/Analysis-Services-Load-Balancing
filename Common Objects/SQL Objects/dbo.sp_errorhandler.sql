CREATE PROCEDURE [error].[sp_errorhandler]
       @ErrorMessage      nvarchar(4000),
	   @ErrorNumber int,
       @ErrorSeverity     int,
       @ErrorState        int,
       @ErrorLine         int,
       @ErrorProc         nvarchar(126),
	   @ErrorXML		xml = NULL,
	   @RaiseError INT = 1

AS
/*===============================================================================================
|	errorhandler
|	Created By Raymond Honderdors
|	
|	Standardized error handler procedure
|
===============================================================================================*/

/*===============================================================================================
	Change Log
	2013-09-09		Raymond		v1.0.1		Added version control
											Allow Error Messafe XML from source
===============================================================================================*/
BEGIN /*[error].[sp_errorhandler]*/
	
	DECLARE 
		@Msg xml,
		@current_time datetime2(7),
		@version nvarchar(max) = ''
/*
================================================================================================
*/
	SET @version = 'v1.0.1'
/*
================================================================================================
*/

	SET @ErrorState = CASE WHEN @ErrorState BETWEEN 1 AND 127 THEN @ErrorState ELSE 1 END
	SET @ErrorProc = isnull(@ErrorProc,CONVERT(nvarchar(126),object_name(@@PROCID)))
 
	IF (@@TRANCOUNT>0)
		ROLLBACK TRANSACTION
 
	SET @current_time = ISNULL(@current_time, GETUTCDATE())
 
	IF @ErrorXML IS NULL
	BEGIN
		SET 
			@Msg = (SELECT @current_time  AS 'EventTime'
			, @ErrorProc        AS 'ObjectName'
			, @ErrorNumber            AS 'Error/Number'
			, @ErrorMessage     AS 'Error/Message'
			, @ErrorSeverity    AS 'Error/Severity'
			, @ErrorState             AS 'Error/State'
			, @ErrorLine        AS 'Error/Line'
			, @version			AS 'Error/Version'
		FOR XML PATH('Event'))
	END
	ELSE
	BEGIN
		SET @Msg = @ErrorXML
	END

 
	INSERT INTO [error].[errorlog] (EventTime, Priority, Component, Errormsg)
	VALUES (@current_time, 'ERROR', @ErrorProc, @Msg)
	IF @RaiseError = 1
	BEGIN
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
	END
END /*[dbo].[sp_errorhandler]*/