CREATE PROCEDURE [setup].[performancecounterlist]
AS
BEGIN
    DECLARE @CounterList NVARCHAR(MAX);
    SELECT @CounterList = STUFF(
    (
        SELECT '|' + [c].[categoryname] + ';' + [c].[countername] + ';' + [c].[instancename]
        FROM [setup].[countermappings] AS [c]
        GROUP BY [c].[categoryname],
            [c].[countername],
            [c].[instancename]
        FOR XML PATH(''), TYPE
    ).[value]('.', 'NVARCHAR(MAX)'),
                                   1,
                                   1,
                                   ''
                               );
    SELECT REPLACE(REPLACE(@CounterList, ';;|', '|'), ';|', '|');
END;