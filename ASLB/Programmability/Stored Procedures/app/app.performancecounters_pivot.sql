CREATE PROCEDURE [app].[performancecounters_pivot]
AS
BEGIN
    DECLARE @cols AS NVARCHAR(MAX),
    @colssum NVARCHAR(MAX),
    @query AS NVARCHAR(MAX);

SELECT [p].[performancecounters_id],
    [p].[collection_id],
    [p].[collection_time],
    [p].[categoryname],
    [p].[countername],
    [p].[instancename],
    [p].[categoryname] + [p].[countername] + [p].[instancename] AS [pivcol],
    [p].[machinename],
    [p].[countervalue]
INTO [#data]
FROM [log].[performancecounters] AS [p] WITH (NOLOCK)
    INNER JOIN
     (
         SELECT [p].[machinename],
             MAX([p].[collection_time]) AS [collection_time]
         FROM [log].[performancecounters] AS [p] WITH (NOLOCK)
         GROUP BY [p].[machinename]
     ) AS [lastlog]
        ON [lastlog].[machinename] = [p].[machinename]
           AND [lastlog].[collection_time] = [p].[collection_time];


SELECT @cols = STUFF(
(
    SELECT ',' + QUOTENAME([d].[pivcol])
    FROM [#data] AS [d]
    GROUP BY [d].[pivcol]
    ORDER BY [d].[pivcol]
    FOR XML PATH(''), TYPE
).[value]('.', 'NVARCHAR(MAX)'),
                        1,
                        1,
                        ''
                    );
SELECT @colssum = STUFF(
(
    SELECT ', SUM(' + QUOTENAME([d].[pivcol]) + ') AS ' + QUOTENAME([d].[pivcol])
    FROM [#data] AS [d]
    GROUP BY [d].[pivcol]
    ORDER BY [d].[pivcol]
    FOR XML PATH(''), TYPE
).[value]('.', 'NVARCHAR(MAX)'),
                           1,
                           1,
                           ''
                       );
SET @query
    = 'SELECT machinename,[collection_time],' + @colssum
      + ' from 
             (
SELECT [p].[performancecounters_id],
    [p].[collection_id],
    [p].[collection_time],
    [p].[categoryname],
    [p].[countername],
    [p].[instancename],

	[p].[categoryname] + [p].[countername]+ [p].[instancename] AS pivcol,

    [p].[machinename],
    [p].[countervalue]

FROM [log].[performancecounters] AS [p] WITH (NOLOCK)
    /*INNER JOIN
     (
         SELECT [p].[machinename],
             MAX([p].[collection_time]) AS [collection_time]
         FROM [log].[performancecounters] AS [p] WITH (NOLOCK)
         GROUP BY [p].[machinename]
     ) AS [lastlog]
        ON [lastlog].[machinename] = [p].[machinename]
           AND [lastlog].[collection_time] = [p].[collection_time]*/
            ) x
            pivot 
            (
                sum(countervalue)
                for [pivcol] in (' + @cols + ')
            ) p group by machinename,[collection_time] order by [collection_time],machinename';
--PRINT @query;
EXECUTE (@query);
DROP TABLE [#data];
END
