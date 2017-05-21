CREATE PROC [dbo].[sp_GenericMerge]
    (
      @sourceschema NVARCHAR(100) ,
      @targetschema NVARCHAR(100) ,
      @tablename NVARCHAR(200) ,
      @targettablename NVARCHAR(200) = NULL ,
      @logschema NVARCHAR(100) = NULL ,
      @addvalues INT = 0 ,
      @UseBatch INT = 0 ,
      @useview INT = 0 ,
      @Pkonly INT = 1 ,
      @IsEntity INT = 1 ,
      @CheckColumnExclusion INT = 0 ,
      @debug INT = 0
    )
AS
    DECLARE @schemaiddelta INT ,
        @schemaidentities INT ,
        @schemaidlog INT

    DECLARE @objectdelta INT ,
        @objectentities INT ,
        @objectlog INT ,
        @IdenditySeed INT
    DECLARE @matchcolimns NVARCHAR(MAX) = '' ,
        @sqlmerge NVARCHAR(MAX) = '' ,
        @updatecolimns NVARCHAR(MAX)= '' ,
        @insertecolimns NVARCHAR(MAX)= '' ,
        @valuesecolimns NVARCHAR(MAX)= '' ,
        @resultcolimns NVARCHAR(MAX)= '' ,
        @resultcolimns1 NVARCHAR(MAX)= '' ,
        @temptable NVARCHAR(MAX) ,
        @temptablenewcolumn NVARCHAR(MAX) = '' ,
        @SourceColumn NVARCHAR(MAX) = '' ,
        @TargetColumn NVARCHAR(MAX) = '' ,
		@ExistsTable NVARCHAR(MAX),
        @SGV_ColumnList NVARCHAR(MAX) ,
        @SGV_ValueList NVARCHAR(MAX) ,
        @Exclusion_List NVARCHAR(MAX),
		@SGV_ViewSuffix NVARCHAR(MAX)
    DECLARE @logid UNIQUEIDENTIFIER ,
        @cteSource NVARCHAR(MAX) = '' ,
        @cteColumns NVARCHAR(MAX) = '' ,
        @lastdatechanged INT = 0
    DECLARE @Version NVARCHAR(MAX) = ''

    DECLARE @SummaryOfChanges TABLE ( Change VARCHAR(20) )
--set @tablename ='AdvertiserBrands'
--set @sourceschema ='delta'
--set @targetschema='entities'
--set @logschema = 'log'
/*
=
=	Generic Merge
=	by Raymonnd Honderdors
=	2013-05-01
=	
=	Generates and executes a merge statement between 2 tables  with the same name in different schema's. 
=	Also Supported is view to table merge, the view needs to be like v_<destination>
=	the Join is based on the destinations PK or PK + all unique
=	it can also write to a log table in a log schema, the table name is the same
=	for numeric values it can allow for add's instead of updates
*/
/*Version Control*/
    SET @Version = 'v 1.2.04'
/*
=	Version		Date			Auther					Description
=	v 1.0.8		2013-06-18		Raymond Honderdors		Fix a bug with the bacth_id, do not add the column if already on the table / view
=	v 1.0.9		2013-06-18		Raymond HOnderdors		Fix a bug to not run if source table / view is empty
=	v 1.0.10	2013-06-19		Raymond Honderdors		Capture first column name from source and Target
=	v 1.0.11	2013-06-20		Raymond	Honderdors		Allow the use of current batch_id or create a new batch from traget table
=	v 1.0.12	2013-06-20		Raymond Honderdors		Removed duplication of where clause if there is a cloumn called lastdatechanged
=	v 1.0.13	2013-06-24		Raymond Honderdors		Do not allow smaller batches to be merged / inserted in to target table
=	v 1.0.14	2013-06-24		Raymond Honderdors		Fix bug with Batch Id match see version v 1.0.13
=	V 1.0.15	2013-06-24		Raymond Honderdors		Add @IsEntity to control when to check the batch or not (only for entities)
=	v 1.0.16	2013-06-25		Raymond	Honderdors		Fix Batch-control check, to not preform when it is a view
=	v 1.0.16	2013-06-25		Raymond	Honderdors		Fix a bug when there is Batch_id on the insert we should not add the values batch_id twice
=	v 1.1.0		2013-08-29		Raymond Honderdors		Restructure  + Performance Fix CTE used in Merge On statement
=														Allow for target to be a different table name than source, incase source is view, prefix "v_" will be added
=														If target table is not specified it will be copied from source table name, as it was untill version 1.0.21
=	v 1.1.1		2013-08-29		Raymond Honderdors		Removed Batch Check for all (Fact view --> Table / Entities Table --> Table
=	v 1.1.2		2013-08-29		Raymond Honderdors		
=	v 1.1.5		2013-09-03		Raymond Honderdors		Fixed the CTE for @lastdatechanged condition 
=	v 1.1.6		2013-09-09		Raymond Honderdors		Bug on NOT Matched Condition, do not check target table
=	v 1.1.7		2013-09-12		Raymond Honderdors		Add NOLOCK hint to all system Tables
=	v 1.1.8		2013-09-29		Raymond Honderdors		When @IsEntity = 0 and  @useview = 1, S.[Batch_ID] >= T.[Batch_ID]
=	v 1.1.9		2013-09-29		Raymond Honderdors		Moved logic from V1.1.8 to the macthed column variable
=	v 1.1.10	2013-09-29		Raymond Honderdors		Bug Fix on the Match condition for Factdata
=	v 1.1.11	2013-12-12		Raymond Honderdors		Bug Fix stop the update of batchid when batchid is part of Unique or PK
=	V 1.2.01	2013-12-18		Raymond Honderdors		Fix Log Table column missmatch (Add Column Only)
=														Added Cloumn Exclusion Logic, to not update certain table if column has a certain value
=														Required is to have 2 system global variables (Generic_Merge_Exclude_Columns, Generic_Merge_Exclude_Values)
=														Added to project a SQL CMD Variable "$(SSIS_LOG_DB)"
=	V 1.2.02	2013-12-18		Raymond Honderdors		bug found with exclude column
=	V 1.2.03	2014-05-22		Raymond Honderdors		Fix Performance with exist from view
=														Add Suffix on Exist View (from SGV)
=	V 1.2.04	2014-11-16		Raymond Honderdors		Remove Batch_ID column from cte if not on source table, and used in row function
===============================================================================================================================
=
=		object delta = source
=		object entities = destination
*/
/*
	Version Number Will Be printed when in debug mode
*/


    IF @debug = 1
        BEGIN
            PRINT 'Debug Flag Set, No execution will be preformed'
            PRINT @Version
        END

    IF @targettablename IS NULL
        BEGIN
            SET @targettablename = @tablename
            IF @debug = 1
                BEGIN
                    PRINT 'Targettable = SourceTable'
                    PRINT @tablename
                END
        END

    IF @Pkonly NOT IN ( 1, 0 )
        BEGIN
            SET @Pkonly = 1
            IF @debug = 1
                BEGIN
                    PRINT 'Use PK Only Flag - overwrite due to wrong input'
                    PRINT @Pkonly
                END
        END
	
	SELECT @SGV_ViewSuffix = ISNULL([$(SSIS_LOG_DB)].[dbo].[SQL_FN_GetSystemPropertyValue]('Generic_Merge_View_Suffix'),'')

	/*The list is seperated by ";"*/
    IF @CheckColumnExclusion = 1
        BEGIN
            SELECT  @SGV_ColumnList = ISNULL([$(SSIS_LOG_DB)].[dbo].[SQL_FN_GetSystemPropertyValue]('Generic_Merge_Exclude_Columns'),
                                             '') ,
                    @SGV_ValueList = ISNULL([$(SSIS_LOG_DB)].[dbo].[SQL_FN_GetSystemPropertyValue]('Generic_Merge_Exclude_Values'),
                                            '')
		/*Create 2 Temp tables to hold the data from the SGV*/
            IF ( LEN(@SGV_ColumnList) > 0
                 AND LEN(@SGV_ValueList) > 0
               )
                BEGIN
                    SELECT  *
                    INTO    #TempColumns
                    FROM    [$(SSIS_LOG_DB)].[dbo].[SQL_FN_ParseDelimitedString](';',
                                                              @SGV_ColumnList)
                    SELECT  *
                    INTO    #TempValues
                    FROM    [$(SSIS_LOG_DB)].[dbo].[SQL_FN_ParseDelimitedString](';',
                                                              @SGV_ValueList)
                END
            ELSE
                BEGIN
                    SET @CheckColumnExclusion = 0
                    PRINT 'Generic_Merge_Exclude_Columns or Generic_Merge_Exclude_Values are not configured, no exclusion will occur' 
                END
		/*Create 2 Temp tables to hold the data from the SGV*/

		/*
		Example Select:
			select	T1.pn, T1.s as [name], T2.s as [value]
			from #TempColumns T1 inner join #TempValues T2 in T1.pn = T2.pn
		*/
        END



    SET NOCOUNT ON  
    BEGIN TRY
		/*START Get Schema_id's*/
        SELECT  @schemaiddelta = schema_id
        FROM    sys.schemas WITH ( NOLOCK )
        WHERE   name = @sourceschema
        SELECT  @schemaidentities = schema_id
        FROM    sys.schemas WITH ( NOLOCK )
        WHERE   name = @targetschema
		/*Start Logging*/
        IF @logschema IS NOT NULL
            BEGIN
                SELECT  @schemaidlog = schema_id
                FROM    sys.schemas WITH ( NOLOCK )
                WHERE   name = @logschema
                SET @logid = NEWID()
            END
		/*End Logging*/
	/*END Get Schema_id's*/

	--select @schemaiddelta,@schemaidentities,@schemaidlog

	/*START Get object_id's*/
        IF @useview <> 0
            BEGIN
			--SET @tablename = 
			--print @tablename
                SELECT  @objectdelta = object_id
                FROM    sys.views WITH ( NOLOCK )
                WHERE   schema_id = @schemaiddelta
                        AND name = 'v_' + @tablename
				IF LEN(ISNULL(@SGV_ViewSuffix,'')) > 0 
				BEGIN
					SET @SGV_ViewSuffix = '_' + @SGV_ViewSuffix
				END
				/*Test is we have view with suffix*/
				IF EXISTS(SELECT 1  FROM sys.views AS v WITH (NOLOCK) WHERE schema_id = @schemaiddelta
                        AND name = 'v_' + @tablename + @SGV_ViewSuffix)
					BEGIN
						SET @ExistsTable = 'v_' + @tablename + @SGV_ViewSuffix
					END
				ELSE
				BEGIN
					SET @ExistsTable = 'v_' + @tablename
				END
            END
        ELSE
            BEGIN
                SELECT  @objectdelta = object_id
                FROM    sys.tables WITH ( NOLOCK )
                WHERE   schema_id = @schemaiddelta
                        AND name = @tablename
				SET @ExistsTable = @tablename
            END
        SELECT  @objectentities = object_id
        FROM    sys.tables WITH ( NOLOCK )
        WHERE   schema_id = @schemaidentities
                AND name = @targettablename
        IF @logschema IS NOT NULL
            BEGIN
                SELECT  @objectlog = object_id
                FROM    sys.tables WITH ( NOLOCK )
                WHERE   schema_id = @schemaidlog
                        AND name = @targettablename
            END

        IF @debug = 1
            BEGIN
                IF @useview <> 0
                    BEGIN
                        PRINT 'Source Schema :' + @sourceschema + '('
                            + CAST(@schemaiddelta AS NVARCHAR(MAX))
                            + ') Table / View ' + 'v_' + @tablename 
                    END
                ELSE
                    BEGIN
                        PRINT 'Source Schema :' + @sourceschema + '('
                            + CAST(@schemaiddelta AS NVARCHAR(MAX))
                            + ') Table / View ' + @tablename 
                    END
                PRINT 'Target Schema :' + @targetschema + '('
                    + CAST(@schemaidentities AS NVARCHAR(MAX)) + ') Table '
                    + @targettablename
                IF @logschema IS NOT NULL
                    BEGIN
                        PRINT 'Log Schema :' + @logschema + '('
                            + CAST(@schemaidlog AS NVARCHAR(MAX)) + ') Table '
                            + @targettablename
                    END
                ELSE
                    BEGIN
                        PRINT 'Logging not enabled'
                    END
            END


	/*END Get object_id's*/
	/*Get First column name from source and target*/
        SELECT TOP 1
                @SourceColumn = name
        FROM    sys.columns WITH ( NOLOCK )
        WHERE   object_id = @objectdelta
        SELECT TOP 1
                @TargetColumn = name
        FROM    sys.columns WITH ( NOLOCK )
        WHERE   object_id = @objectentities
/*===========================================================================================================================================*/
        IF @CheckColumnExclusion = 1
            BEGIN
	/*Check if source exclusion Columns*/
                IF EXISTS ( SELECT  c.*
                            FROM    sys.columns c WITH ( NOLOCK )
                                    LEFT OUTER JOIN ( SELECT  ic.object_id ,
                                                              ic.column_id
                                                      FROM    sys.index_columns ic
                                                              WITH ( NOLOCK )
                                                              INNER JOIN ( SELECT
                                                              object_id ,
                                                              index_id
                                                              FROM
                                                              sys.indexes WITH ( NOLOCK )
                                                              WHERE
                                                              object_id IN (
                                                              @objectentities )
                                                              AND is_unique = 1
                                                              AND is_primary_key IN (
                                                              1, @Pkonly )
                                                              ) i ON ic.object_id = I.object_id
                                                              AND ic.index_id = i.index_id
                                                      WHERE   is_included_column = 0
                                                    ) ic ON c.object_id = ic.object_id
                                                            AND c.column_id = ic.column_id
                                    INNER JOIN #TempColumns T1 ON c.name = T1.s
                            WHERE   c.object_id = @objectdelta
                                    AND ic.column_id IS NULL )
                    BEGIN
                        SET @CheckColumnExclusion = 1 /*At least 1 Exclusion Column Found on Source Table*/
                        SET @Exclusion_List = ''
                        SELECT  @Exclusion_List = @Exclusion_List + 'CAST(V.['
                                + C.name + '] as NVARCHAR(MAX)) = ''' + T2.s
                                + ''''
                        FROM    sys.columns c WITH ( NOLOCK )
                                LEFT OUTER JOIN ( SELECT    ic.object_id ,
                                                            ic.column_id
                                                  FROM      sys.index_columns ic
                                                            WITH ( NOLOCK )
                                                            INNER JOIN ( SELECT
                                                              object_id ,
                                                              index_id
                                                              FROM
                                                              sys.indexes WITH ( NOLOCK )
                                                              WHERE
                                                              object_id IN (
                                                              @objectentities )
                                                              AND is_unique = 1
                                                              AND is_primary_key IN (
                                                              1, @Pkonly )
                                                              ) i ON ic.object_id = I.object_id
                                                              AND ic.index_id = i.index_id
                                                  WHERE     is_included_column = 0
                                                ) ic ON c.object_id = ic.object_id
                                                        AND c.column_id = ic.column_id
                                INNER JOIN #TempColumns T1 ON c.name = T1.s
                                INNER JOIN #TempValues T2 ON T1.pn = T2.pn
                        WHERE   c.object_id = @objectdelta
                                AND ic.column_id IS NULL
                    END
                ELSE
                    BEGIN
                        SET @CheckColumnExclusion = 0 /*No Exclusion Column Found on Source Table*/
                    END
                IF ( @debug = 1
                     AND @CheckColumnExclusion = 1
                   )
                    BEGIN
                        PRINT 'Exclusion Columns'
                        PRINT 'SGV COLUMNS:' + @SGV_ColumnList
                        PRINT 'SGV VALUES :' + @SGV_ValueList
                        PRINT 'Exclusion List:' + @Exclusion_List
                    END

            END
	/*Check if Destination has LastDateChanged Column*/
        IF EXISTS ( SELECT  c.*
                    FROM    sys.columns c WITH ( NOLOCK )
                            LEFT OUTER JOIN ( SELECT    ic.object_id ,
                                                        ic.column_id
                                              FROM      sys.index_columns ic
                                                        WITH ( NOLOCK )
                                                        INNER JOIN ( SELECT
                                                              object_id ,
                                                              index_id
                                                              FROM
                                                              sys.indexes WITH ( NOLOCK )
                                                              WHERE
                                                              object_id IN (
                                                              @objectentities )
                                                              AND is_unique = 1
                                                              AND is_primary_key IN (
                                                              1, @Pkonly )
                                                              ) i ON ic.object_id = I.object_id
                                                              AND ic.index_id = i.index_id
                                              WHERE     is_included_column = 0
                                            ) ic ON c.object_id = ic.object_id
                                                    AND c.column_id = ic.column_id
                    WHERE   c.object_id = @objectentities
                            AND ic.column_id IS NULL
                            AND C.name LIKE 'lastdatechanged' )
            BEGIN
                SET @lastdatechanged = 1
            END
        ELSE
            BEGIN
                SET @lastdatechanged = 0
            END
        IF @debug = 1
            BEGIN
                PRINT 'Lastdatechanged column status:'
                    + CAST(@lastdatechanged AS NVARCHAR(MAX))
            END
/*===========================================================================================================================================*/

	/*Start Get Columns to match (PK / Unique)*/
        SELECT
		/*As Fix for V1.1.10, Reformated @matchcolimns, When usebatch is 0 we willl not comapre the batch column*/
		--@matchcolimns = @matchcolimns + 'S.' + name  + CASE WHEN Lower(NAME)  = 'batch_id' THEN CASE WHEN (@useview =1 AND @IsEntity =0 AND @UseBatch =1 ) THEN ' >= ' ELSE ' > ' END ELSE ' = ' END + 'T.' + name + ';',
                @matchcolimns = @matchcolimns
                + /*Source*/
			CASE WHEN LOWER(NAME) = 'batch_id'
                 THEN CASE WHEN @UseBatch = 1 THEN 'S.' + name
                           ELSE ''
                      END
                 ELSE 'S.' + name
            END
                + /*Compare*/
			CASE WHEN LOWER(NAME) = 'batch_id'
                 THEN CASE WHEN @UseBatch = 1
                           THEN CASE WHEN ( @useview = 1
                                            AND @IsEntity = 0
                                            AND @UseBatch = 1
                                          ) THEN ' >= '
                                     ELSE ' > '
                                END
                           ELSE ''
                      END
                 ELSE ' = '
            END
                + /*Target*/
			CASE WHEN LOWER(NAME) = 'batch_id'
                 THEN CASE WHEN @UseBatch = 1 THEN 'T.' + name + ';'
                           ELSE ''
                      END
                 ELSE 'T.' + name + ';'
            END ,/*Removed commented lines 2013-12-12*/
                @cteColumns = @cteColumns + name + ';'
        FROM    sys.columns c WITH ( NOLOCK )
                INNER JOIN ( SELECT ic.object_id ,
                                    ic.column_id
                             FROM   sys.index_columns ic WITH ( NOLOCK )
                                    INNER JOIN ( SELECT object_id ,
                                                        index_id
                                                 FROM   sys.indexes WITH ( NOLOCK )
                                                 WHERE  object_id IN (
                                                        @objectentities )
                                                        AND is_unique = 1
                                                        AND is_primary_key IN (
                                                        1, @Pkonly )
                                               ) i ON ic.object_id = I.object_id
                                                      AND ic.index_id = i.index_id
                             WHERE  is_included_column = 0
                           ) ic ON c.object_id = ic.object_id
                                   AND c.column_id = ic.column_id
	/*End Get Columns to match (PK / Unique)*/

	/*build Update string*/

	/*
		tinyint	48
		smallint	52
		int	56
		real	59
		money	60
		float	62
		decimal	106
		numeric	108
		smallmoney	122
		bigint	127
	*/

        SET @updatecolimns = 'UPDATE SET '
        SELECT  @updatecolimns = CASE WHEN @addvalues = 1
                                           AND c.delta_system_type_id IN ( 48,
                                                              52, 56, 59, 60,
                                                              62, 106, 108,
                                                              122, 127 )
                                           AND c.delta_name <> 'batch_id'
                                      THEN @updatecolimns + '['
                                           + c.entities_name + '] = S.['
                                           + c.delta_name + '] + T.['
                                           + c.entities_name + '],'
                                      ELSE @updatecolimns + '['
                                           + c.entities_name + '] = S.['
                                           + c.delta_name + '],'
                                 END
        FROM    ( SELECT    delta.column_id AS delta_column_id ,
                            delta.name AS delta_name ,
                            delta.collation_name AS delta_collation_name ,
                            delta.system_type_id AS delta_system_type_id ,
                            delta.max_length AS delta_max_length ,
                            delta.precision AS delta_precision ,
                            delta.scale AS delta_scale ,
                            delta.is_nullable AS delta_is_nullable ,
                            entities.column_id AS entities_column_id ,
                            entities.name AS entities_name ,
                            entities.collation_name AS entities_collation_name ,
                            entities.system_type_id AS entities_system_type_id ,
                            entities.max_length AS entities_max_length ,
                            entities.precision AS entities_precision ,
                            entities.scale AS entities_scale ,
                            entities.is_nullable AS entities_is_nullable
                  FROM      ( SELECT    *
                              FROM      sys.columns WITH ( NOLOCK )
                              WHERE     object_id = @objectdelta
                            ) delta
                            INNER JOIN ( SELECT c.*
                                         FROM   sys.columns c WITH ( NOLOCK )
                                                LEFT OUTER JOIN ( SELECT
                                                              ic.object_id ,
                                                              ic.column_id
                                                              FROM
                                                              sys.index_columns ic
                                                              WITH ( NOLOCK )
                                                              INNER JOIN ( SELECT
                                                              object_id ,
                                                              index_id
                                                              FROM
                                                              sys.indexes WITH ( NOLOCK )
                                                              WHERE
                                                              object_id IN (
                                                              @objectentities )
                                                              AND is_unique = 1
                                                              AND is_primary_key IN (
                                                              1, @Pkonly )
                                                              ) i ON ic.object_id = I.object_id
                                                              AND ic.index_id = i.index_id
                                                              WHERE
                                                              is_included_column = 0
                                                              ) ic ON c.object_id = ic.object_id
                                                              AND c.column_id = ic.column_id
                                         WHERE  c.object_id = @objectentities
                                                AND ic.column_id IS NULL
                                       ) entities ON delta.name = entities.name
                ) c
	/*build insert string*/
        SET @insertecolimns = ''
        SET @IdenditySeed = 0
        SELECT  @insertecolimns = @insertecolimns + '[' + c.entities_name
                + '],' ,
                @IdenditySeed = @IdenditySeed + c.is_identity
        FROM    ( SELECT    delta.column_id AS delta_column_id ,
                            delta.name AS delta_name ,
                            delta.collation_name AS delta_collation_name ,
                            delta.system_type_id AS delta_system_type_id ,
                            delta.max_length AS delta_max_length ,
                            delta.precision AS delta_precision ,
                            delta.scale AS delta_scale ,
                            delta.is_nullable AS delta_is_nullable ,
                            entities.column_id AS entities_column_id ,
                            entities.name AS entities_name ,
                            entities.collation_name AS entities_collation_name ,
                            entities.system_type_id AS entities_system_type_id ,
                            entities.max_length AS entities_max_length ,
                            entities.precision AS entities_precision ,
                            entities.scale AS entities_scale ,
                            entities.is_nullable AS entities_is_nullable ,
                            entities.is_identity
                  FROM      ( SELECT    *
                              FROM      sys.columns WITH ( NOLOCK )
                              WHERE     object_id = @objectdelta
                            ) delta
                            INNER JOIN ( SELECT c.*
                                         FROM   sys.columns c WITH ( NOLOCK )
                                         WHERE  c.object_id = @objectentities
                                       ) entities ON delta.name = entities.name
                ) c
        ORDER BY c.delta_name
	/*build values string*/
        SET @valuesecolimns = ''
        SELECT  @valuesecolimns = @valuesecolimns
                + CASE WHEN c.delta_name = 'batch_id'
                            AND @UseBatch = 0 THEN '@NewBatchID,'
                       ELSE '[' + c.delta_name + '],'
                  END
        FROM    ( SELECT    delta.column_id AS delta_column_id ,
                            delta.name AS delta_name ,
                            delta.collation_name AS delta_collation_name ,
                            delta.system_type_id AS delta_system_type_id ,
                            delta.max_length AS delta_max_length ,
                            delta.precision AS delta_precision ,
                            delta.scale AS delta_scale ,
                            delta.is_nullable AS delta_is_nullable ,
                            entities.column_id AS entities_column_id ,
                            entities.name AS entities_name ,
                            entities.collation_name AS entities_collation_name ,
                            entities.system_type_id AS entities_system_type_id ,
                            entities.max_length AS entities_max_length ,
                            entities.precision AS entities_precision ,
                            entities.scale AS entities_scale ,
                            entities.is_nullable AS entities_is_nullable
                  FROM      ( SELECT    *
                              FROM      sys.COLUMNS WITH ( NOLOCK )
                              WHERE     object_id = @objectdelta
                            ) delta
                            INNER JOIN ( SELECT c.*
                                         FROM   sys.columns c WITH ( NOLOCK )
                                         WHERE  c.object_id = @objectentities
                                       ) entities ON delta.name = entities.name
                ) c
        ORDER BY c.delta_name
	/**/
	
        SET @resultcolimns = ''
        SELECT  @resultcolimns = @resultcolimns + '
		deleted.[' + c.entities_name + '],
		inserted.[' + c.delta_name + '] AS [New_' + c.delta_name + '],'
        FROM    ( SELECT    delta.column_id AS delta_column_id ,
                            delta.name AS delta_name ,
                            delta.collation_name AS delta_collation_name ,
                            delta.system_type_id AS delta_system_type_id ,
                            delta.max_length AS delta_max_length ,
                            delta.precision AS delta_precision ,
                            delta.scale AS delta_scale ,
                            delta.is_nullable AS delta_is_nullable ,
                            entities.column_id AS entities_column_id ,
                            entities.name AS entities_name ,
                            entities.collation_name AS entities_collation_name ,
                            entities.system_type_id AS entities_system_type_id ,
                            entities.max_length AS entities_max_length ,
                            entities.precision AS entities_precision ,
                            entities.scale AS entities_scale ,
                            entities.is_nullable AS entities_is_nullable
                  FROM      ( SELECT    *
                              FROM      sys.columns WITH ( NOLOCK )
                              WHERE     object_id = @objectdelta
                            ) delta
                            INNER JOIN ( SELECT c.*
                                         FROM   sys.columns c WITH ( NOLOCK )
                                         WHERE  c.object_id = @objectentities
                                       ) entities ON delta.name = entities.name
                ) c
	/*
		56 int
		231 nvarchar
		167 varchar
		61 datetime
	*/

	--SELECT * FROM sys.types
        IF @logschema IS NOT NULL
            BEGIN
                SET @temptable = 'Declare @table table (GUID uniqueidentifier, eventDate datetime, action nvarchar(20),'
                SELECT  @temptable = @temptable + '[' + c.entities_name + '] '
                        + c.entities_typename
                        + CASE WHEN c.entities_system_type_id IN ( 231, 167,
                                                              175, 239 )
                               THEN ' ('
                                    + CAST(c.entities_max_length AS NVARCHAR(10))
                                    + ') '
                               ELSE ''
                          END + ', ' + '[New_' + c.delta_name + '] '
                        + c.delta_typename
                        + CASE WHEN c.delta_system_type_id IN ( 231, 167, 175,
                                                              239 )
                               THEN ' ('
                                    + CAST(c.delta_max_length AS NVARCHAR(10))
                                    + ') '
                               ELSE ''
                          END + ','
                FROM    ( SELECT    delta.column_id AS delta_column_id ,
                                    delta.name AS delta_name ,
                                    delta.collation_name AS delta_collation_name ,
                                    delta.system_type_id AS delta_system_type_id ,
                                    delta.max_length AS delta_max_length ,
                                    delta.precision AS delta_precision ,
                                    delta.scale AS delta_scale ,
                                    delta.is_nullable AS delta_is_nullable ,
                                    delta.typename AS delta_typename ,
                                    entities.column_id AS entities_column_id ,
                                    entities.name AS entities_name ,
                                    entities.collation_name AS entities_collation_name ,
                                    entities.system_type_id AS entities_system_type_id ,
                                    entities.max_length AS entities_max_length ,
                                    entities.precision AS entities_precision ,
                                    entities.scale AS entities_scale ,
                                    entities.is_nullable AS entities_is_nullable ,
                                    entities.typename AS entities_typename
                          FROM      (
				--select * from sys.columns  where object_id = @objectdelta
                                      SELECT    c.* ,
                                                t.name AS typename
                                      FROM      sys.columns c WITH ( NOLOCK )
                                                INNER JOIN sys.types t WITH ( NOLOCK ) ON c.system_type_id = t.system_type_id
                                                              AND c.user_type_id = t.user_type_id
                                      WHERE     c.object_id = @objectdelta
                                    ) delta
                                    INNER JOIN ( SELECT c.* ,
                                                        t.name AS typename
                                                 FROM   sys.columns c WITH ( NOLOCK )
                                                        INNER JOIN sys.types t
                                                        WITH ( NOLOCK ) ON c.system_type_id = t.system_type_id
                                                              AND c.user_type_id = t.user_type_id
                                                 WHERE  c.object_id = @objectentities
                                               ) entities ON delta.name = entities.name
                        ) c
                SET @temptable = LEFT(@temptable, LEN(@temptable) - 1) + ');'

		/*Build Log Table*/
		/*IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DailyImpressionsAgg]') AND type in (N'U'))*/

                SET @temptable = @temptable
                    + '
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''['
                    + @logschema + '].[' + @targettablename
                    + ']'') AND type in (N''U'')) 
		BEGIN
		'
                SET @temptable = @temptable + ' create table [' + @logschema
                    + '].[' + @targettablename
                    + '] (GUID uniqueidentifier, eventDate datetime, action nvarchar(20),'
                SELECT  @temptable = @temptable + '[' + c.entities_name + '] '
                        + c.entities_typename
                        + CASE WHEN c.entities_system_type_id IN ( 231, 167,
                                                              175, 239 )
                               THEN ' ('
                                    + CAST(c.entities_max_length AS NVARCHAR(10))
                                    + ') '
                               ELSE ''
                          END + ', ' + '[New_' + c.delta_name + '] '
                        + c.delta_typename
                        + CASE WHEN c.delta_system_type_id IN ( 231, 167, 175,
                                                              239 )
                               THEN ' ('
                                    + CAST(c.delta_max_length AS NVARCHAR(10))
                                    + ') '
                               ELSE ''
                          END + ',' ,
                        @temptablenewcolumn = @temptablenewcolumn
                        + CASE WHEN c.column_id IS NULL
                               THEN '[' + c.entities_name + '] '
                                    + c.entities_typename
                                    + CASE WHEN c.entities_system_type_id IN (
                                                231, 167, 175, 239 )
                                           THEN ' ('
                                                + CAST(c.entities_max_length AS NVARCHAR(10))
                                                + ') '
                                           ELSE ''
                                      END + ', ' + '[New_' + c.delta_name
                                    + '] ' + c.delta_typename
                                    + CASE WHEN c.delta_system_type_id IN (
                                                231, 167, 175, 239 )
                                           THEN ' ('
                                                + CAST(c.delta_max_length AS NVARCHAR(10))
                                                + ') '
                                           ELSE ''
                                      END + ','
                               ELSE ''
                          END
                FROM    ( SELECT    delta.column_id AS delta_column_id ,
                                    delta.name AS delta_name ,
                                    delta.collation_name AS delta_collation_name ,
                                    delta.system_type_id AS delta_system_type_id ,
                                    delta.max_length AS delta_max_length ,
                                    delta.precision AS delta_precision ,
                                    delta.scale AS delta_scale ,
                                    delta.is_nullable AS delta_is_nullable ,
                                    delta.typename AS delta_typename ,
                                    entities.column_id AS entities_column_id ,
                                    entities.name AS entities_name ,
                                    entities.collation_name AS entities_collation_name ,
                                    entities.system_type_id AS entities_system_type_id ,
                                    entities.max_length AS entities_max_length ,
                                    entities.precision AS entities_precision ,
                                    entities.scale AS entities_scale ,
                                    entities.is_nullable AS entities_is_nullable ,
                                    entities.typename AS entities_typename ,
                                    tlog.column_id AS column_id ,
                                    tlog.name AS name ,
                                    tlog.collation_name AS collation_name ,
                                    tlog.system_type_id AS system_type_id ,
                                    tlog.max_length AS max_length ,
                                    tlog.precision AS precision ,
                                    tlog.scale AS scale ,
                                    tlog.is_nullable AS is_nullable ,
                                    tlog.typename AS typename
                          FROM      (
				--select * from sys.columns  where object_id = @objectdelta
                                      SELECT    c.* ,
                                                t.name AS typename
                                      FROM      sys.columns c WITH ( NOLOCK )
                                                INNER JOIN sys.types t WITH ( NOLOCK ) ON c.system_type_id = t.system_type_id
                                                              AND c.user_type_id = t.user_type_id
                                      WHERE     c.object_id = @objectdelta
                                    ) delta
                                    INNER JOIN ( SELECT c.* ,
                                                        t.name AS typename
                                                 FROM   sys.columns c WITH ( NOLOCK )
                                                        INNER JOIN sys.types t
                                                        WITH ( NOLOCK ) ON c.system_type_id = t.system_type_id
                                                              AND c.user_type_id = t.user_type_id
                                                 WHERE  c.object_id = @objectentities
                                               ) entities ON delta.name = entities.name
                                    LEFT OUTER JOIN ( SELECT  c.* ,
                                                              t.name AS typename
                                                      FROM    sys.columns c
                                                              WITH ( NOLOCK )
                                                              INNER JOIN sys.types t
                                                              WITH ( NOLOCK ) ON c.system_type_id = t.system_type_id
                                                              AND c.user_type_id = t.user_type_id
                                                      WHERE   c.object_id = @objectentities
                                                    ) tlog ON delta.name = tlog.name
                        ) c
                SET @temptable = LEFT(@temptable, LEN(@temptable) - 1)
                    + ') ON [fg_log]
		END'
            END
        IF LEN(@temptablenewcolumn) > 0
            BEGIN
                SET @temptablenewcolumn = LEFT(@temptablenewcolumn,
                                               LEN(@temptablenewcolumn) - 1)
                SET @temptable = @temptable + ' ELSE
			BEGIN
				ALTER TABLE ' + +' ADD ' + @temptablenewcolumn + '
			END'
            END
        SET @temptable = @temptable + ';'
	/*Build CTE Source*/
        IF @useview <> 0
            BEGIN
                IF @UseBatch = 0
                    BEGIN
			--SET @cteSource = + '
			--	DECLARE @NewBatchID BIGINT
			--	SELECT @NewBatchID = ISNULL(MAX(batch_id),0) + 1 FROM ['+ @targetschema + '].[' + @targettablename + ']'
                        SET @cteSource = +'
				DECLARE @NewBatchID BIGINT
				SELECT @NewBatchID = ISNULL(MAX(batch_id),0) + 1 FROM ['
                            + @targetschema + '].[' + @tablename + ']'
                    END
			--SET @cteSource = @cteSource + '
			--	;WITH CTE AS (SELECT v.* FROM ['+ @targetschema + '].[' + @targettablename + '] T FULL OUTER JOIN ['+ @sourceschema + '].[' + 'v_' + @tablename + '] V ON ' + replace(replace(left(@matchcolimns,len(@matchcolimns) -1),';', ' AND '), 'S.','V.')
                SET @cteSource = @cteSource + '
				;WITH CTE AS (SELECT v.* FROM [' + @sourceschema + '].['
                    + 'v_' + @tablename + '] V '
                IF @lastdatechanged = 1
                    BEGIN
                        SET @cteSource = @cteSource + ' FULL OUTER JOIN ['
                            + @targetschema + '].[' + @targettablename
                            + '] T ON ' + REPLACE(REPLACE(LEFT(@matchcolimns,
                                                              LEN(@matchcolimns)
                                                              - 1), ';',
                                                          ' AND '), 'S.', 'V.')
                            + ' WHERE ISNULL(T.lastdatechanged,''2000-01-01'') <> V.lastdatechanged ' 
				--SET @cteSource =  @cteSource +' AND v.['+@SourceColumn+'] IS NOT NULL)'
                    END
                IF @CheckColumnExclusion = 1
                    BEGIN
                        SET @cteSource = @cteSource
                            + CASE WHEN @lastdatechanged = 1 THEN ' AND '
                                   ELSE ' WHERE '
                              END + @Exclusion_List
					/*Need to Have Coulmns from Source That matched the exclusion + the value match*/
                    END
			--ELSE
			--BEGIN
			--	SET @cteSource =  @cteSource +' WHERE v.['+@SourceColumn+'] IS NOT NULL)'
			--END
                SET @cteSource = @cteSource + ')'
            END
        ELSE
            BEGIN
                SET @cteSource = ';WITH CTE AS (SELECT '
                    + LEFT(@insertecolimns, LEN(@insertecolimns) - 1)
                    + ',ROW_NUMBER() OVER (PARTITION BY '
                    + REPLACE(LEFT(@cteColumns, LEN(@cteColumns) - 1), ';',
                              ', ') + ' Order By ' + REPLACE(LEFT(@cteColumns,
                                                              LEN(@cteColumns)
                                                              - 1), ';', ', ')
					
					IF(CHARINDEX('batch_id',LOWER(@cteColumns)) >0 )
					BEGIN
						SET @cteSource = @cteSource + ', batch_id desc'
					END /*Only Add Bacth_id if included in source table*/
					SET @cteSource = @cteSource +') As RowNum FROM [' + @sourceschema
                    + '].[' + @tablename + '] '

                IF @CheckColumnExclusion = 1
                    BEGIN
                        SET @cteSource = @cteSource
                            + CASE WHEN @lastdatechanged = 1 THEN ' AND '
                                   ELSE ' WHERE '
                              END + @Exclusion_List
					/*Need to Have Coulmns from Source That matched the exclusion + the value match*/
                    END
                SET @cteSource = @cteSource + ' )' 
            END
		--print @temptable
	/**/
	 /*Merger Syntax*/
	 /*
		;WITH CTE AS (
		SELECT DATEOn, FullName, FamilyName, Company, Position, ROW_NUMBER() OVER (PARTITION BY FullName Order By FullName) As RowNum From Name
		)
		MERGE Personel AS T  
		USING CTE AS S ON (T.FullName = S.FullName) And Source.RowNum = 1

		ON (Column List)
		WHEN MATCHED BY TARGET -- Update
		WHEN NOT MATCHED BY TARGET -- Insert 
	 */
	/*New to use @ExistsTable instead of @tablename*/
        IF @useview <> 0
            BEGIN
                SET @sqlmerge = 'IF EXISTS(SELECT 1 FROM  [' + @sourceschema
                    + '].[' + @ExistsTable + '])
	BEGIN'
            END
        ELSE
            BEGIN
                SET @sqlmerge = 'IF EXISTS(SELECT 1 FROM  [' + @sourceschema
                    + '].[' + @ExistsTable + '])
	BEGIN'
            END
        IF @IdenditySeed > 0
            BEGIN
                SET @sqlmerge = @sqlmerge + ' 
	SET IDENTITY_INSERT ' + '[' + @targetschema + '].[' + @targettablename
                    + '] ON'
            END
        IF @logschema IS NOT NULL
            BEGIN
		
	--		SET @sqlmerge=@sqlmerge + '
	--INSERT INTO ['+@logschema+'].[' + @tablename + ']
	--SELECT 
	--	* 
	--FROM
	--('

                SET @sqlmerge = @sqlmerge + '
	' + @temptable
            END
	/*/*USING ['+@sourceschema+'].[' + @tablename + '] AS S*/*/	
        IF @lastdatechanged = 1
            BEGIN
                SET @sqlmerge = @sqlmerge
                    + ' DECLARE @Date Datetime2 = Getdate() '
            END
        SET @sqlmerge = @sqlmerge + @cteSource + '
		MERGE ' + '[' + @targetschema + '].[' + @targettablename + '] AS T
		USING (SELECT * FROM CTE'
        IF @useview <> 0
            BEGIN
                SET @sqlmerge = @sqlmerge + ''
            END
        ELSE
            BEGIN
                SET @sqlmerge = @sqlmerge + ' WHERE RowNum=1'
            END

		--IF (CHARINDEX('batch_id',@matchcolimns) =0 and  @useview = 0)
		--BEGIN
		--	SET @matchcolimns = @matchcolimns + '(S.[Batch_ID] > T.[Batch_ID] OR T.[Batch_ID] IS NULL);'
		--END


		/*As Fix for V1.1.10, Reformated, When usebatch is 0 we willl not comapre the batch column*/
        SET @sqlmerge = @sqlmerge + ' ) AS S ON ('
            + REPLACE(LEFT(@matchcolimns, LEN(@matchcolimns) - 1), ';',
                      ' AND ') + ')
		
		WHEN MATCHED '
            + CASE WHEN ( @IsEntity = 1
                          AND @useview = 0
                          AND @UseBatch = 1
                        )
                        OR ( @IsEntity = 0
                             AND @useview = 1
                             AND @UseBatch = 1
                           ) THEN ' AND S.[Batch_ID] > T.[Batch_ID] '
                   ELSE ''
              END + '
		THEN ' + LEFT(@updatecolimns, LEN(@updatecolimns) - 1)
            + CASE WHEN @lastdatechanged = 1
                        AND @useview = 0 THEN ', lastdatechanged = @Date '
                   ELSE ''
              END
            + CASE WHEN @useview = 1
                   THEN CASE WHEN CHARINDEX('S.[batch_id]', @updatecolimns) > 0
                             THEN ''
                             WHEN CHARINDEX('batch_id', @matchcolimns) > 0
                                  AND CHARINDEX('S.[batch_id]', @updatecolimns) = 0
                             THEN ''
                             ELSE ', batch_id = '
                                  + CASE WHEN @UseBatch = 1
                                         THEN 'S.[batch_id]'
                                         ELSE '@NewBatchID'
                                    END
                        END
                   ELSE ''
              END + '
		/*
		WHEN MATCHED '
            + CASE WHEN ( @IsEntity = 1
                          AND @useview = 0
                          AND @UseBatch = 1
                        )
                        OR ( @IsEntity = 0
                             AND @useview = 1
                             AND @UseBatch = 1
                           ) THEN ' AND S.[Batch_ID] <= T.[Batch_ID] '
                   ELSE ''
              END + '
		THEN ' + LEFT(@updatecolimns, LEN(@updatecolimns) - 1)
            + CASE WHEN @lastdatechanged = 1
                        AND @useview = 0 THEN ', lastdatechanged = @Date '
                   ELSE ''
              END
            + CASE WHEN @useview = 1
                   THEN CASE WHEN CHARINDEX('S.[batch_id]', @updatecolimns) > 0
                             THEN ''
                             WHEN CHARINDEX('batch_id', @matchcolimns) > 0
                                  AND CHARINDEX('S.[batch_id]', @updatecolimns) = 0
                             THEN ''
                             ELSE ', batch_id = '
                                  + CASE WHEN @UseBatch = 1
                                         THEN 'S.[batch_id]'
                                         ELSE '@NewBatchID'
                                    END
                        END
                   ELSE ''
              END + '
		*/
		WHEN NOT MATCHED ' /* Removed as of V 1.1.6 --+ CASE WHEN @IsEntity = 0 and  @useview = 1 and @UseBatch = 1 THEN  ' AND ( S.[Batch_ID] > [Batch_ID] OR [Batch_ID] IS NULL)' ELSE '' END*/ 
            + ' 
		THEN INSERT (' + LEFT(@insertecolimns, LEN(@insertecolimns) - 1)
            + CASE WHEN @lastdatechanged = 1
                        AND @useview = 0 THEN ', lastdatechanged '
                   ELSE ''
              END
            + CASE WHEN @useview = 1
                   THEN CASE WHEN CHARINDEX('[batch_id]', @insertecolimns) > 0
                             THEN ''
                             ELSE ', [batch_id]'
                        END
                   ELSE ''
              END + ')
		VALUES (' + LEFT(@valuesecolimns, LEN(@valuesecolimns) - 1)
            + CASE WHEN @lastdatechanged = 1
                        AND @useview = 0 THEN ', @Date '
                   ELSE ''
              END
            + CASE WHEN @useview = 1
                   THEN CASE WHEN CHARINDEX('[batch_id]', @valuesecolimns) > 0
                                  OR CHARINDEX('NewBatchID', @valuesecolimns) > 0
                             THEN ''
                             ELSE ', @NewBatchID'
                        END
                   ELSE ''
              END + ');'
        IF @logschema IS NOT NULL
            BEGIN
                SET @sqlmerge = LEFT(@sqlmerge, LEN(@sqlmerge) - 1) + '
		OUTPUT ''' + CAST(@logid AS NVARCHAR(MAX))
                    + ''' as GUID, getdate() as eventDate, $Action AS Action, '
                    + LEFT(@resultcolimns, LEN(@resultcolimns) - 1) + '
		INTO @table;

		INSERT INTO [' + @logschema + '].[' + @targettablename + ']
		SELECT 
			*
		FROM @table;
		'
	--	Changes ('+left(@resultcolimns1,len(@resultcolimns1)-1)+');'

            END
        IF @IdenditySeed > 0
            BEGIN
                SET @sqlmerge = @sqlmerge + ' 
	SET IDENTITY_INSERT ' + '[' + @targetschema + '].[' + @targettablename
                    + '] OFF'
            END
        IF ( @useview = 1
             AND CHARINDEX('S.[batch_id]', @updatecolimns) > 0
           )
            BEGIN
                IF @UseBatch = 0
                    BEGIN
                        SET @sqlmerge = REPLACE(@sqlmerge, 'S.[batch_id]',
                                                '@NewBatchID')
			--SET @sqlmerge =replace(@sqlmerge,'S.[batch_id]','@NewBatchID')
                    END
            END
        SET @sqlmerge = @sqlmerge + '
	END'
	
        SET NOCOUNT OFF
	
        IF @debug = 1
            BEGIN
                IF LEN(@sqlmerge) < 4000
                    BEGIN
                        PRINT @sqlmerge
                    END
                ELSE
                    BEGIN
                        SELECT  @sqlmerge
                    END
            END
        ELSE
            BEGIN
                BEGIN TRAN
                PRINT 'Exec Start: @' + CONVERT(NVARCHAR(MAX), GETDATE(), 112)  
                EXEC sp_executesql @sqlmerge
                PRINT 'Exec End: @' + CONVERT(NVARCHAR(MAX), GETDATE(), 112)  
                PRINT @@ROWCOUNT
                COMMIT TRAN
            END
	

	
	
        RETURN 0
    END TRY

    BEGIN CATCH
        IF ( @@TRANCOUNT > 0 )
            ROLLBACK TRANSACTION

        DECLARE @ErrorMessage NVARCHAR(4000)
        DECLARE @ErrorNumber INT
        DECLARE @ErrorSeverity INT
        DECLARE @ErrorState INT
        DECLARE @ErrorLine INT
        DECLARE @Msg XML
        DECLARE @ErrorProc NVARCHAR(126)

		
        SET @ErrorState = CASE WHEN @ErrorState BETWEEN 1 AND 127
                               THEN @ErrorState
                               ELSE 1
                          END
        SET @ErrorProc = ISNULL(@ErrorProc,
                                CONVERT(NVARCHAR(126), OBJECT_NAME(@@PROCID)))
		
        SELECT  @ErrorMessage = @Version + ' ' + ERROR_MESSAGE() ,
                @ErrorNumber = ERROR_NUMBER() ,
                @ErrorSeverity = ERROR_SEVERITY() ,
                @ErrorState = ERROR_STATE() ,
                @ErrorLine = ERROR_LINE() ,
                @ErrorProc = ERROR_PROCEDURE()
		
        EXEC [dbo].sp_errorhandler @ErrorMessage = @ErrorMessage,
            @ErrorNumber = @ErrorNumber, @ErrorSeverity = @ErrorSeverity,
            @ErrorState = @ErrorState, @ErrorLine = @ErrorLine,
            @ErrorProc = @ErrorProc
        RETURN @ErrorNumber
    END CATCH