CREATE FUNCTION [setup].[fn_getsystempropertyvalue]
    (
      @Input NVARCHAR(100) = NULL
    )
RETURNS NVARCHAR(4000)
    WITH EXECUTE AS CALLER
 /*
=============================================================
-	Created By:		Raymond Honderdors
-	Created Date:	2012-08-21
-	Description:
-		Get a specific value from system_global_variables
-			Input:
-				@Input nvarchar(100)
-			Output:
-				nvarchar(100)
=============================================================
-	Change Log
-		task 66011:		Create
-	2014-01-02		Raymond Honderdors		Added nolock to the select
-	2014-01-14		Raymond Honderdors		Added nolock to the select -- rollback
=============================================================
*/
    BEGIN
        DECLARE @Output NVARCHAR(max)

        SELECT  @Output = [property_value]
        FROM    [setup].[system_global_variables] --WITH (NOLOCK)
        WHERE   [property_name] = @Input
        RETURN @Output
    END
GO

