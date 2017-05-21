CREATE PROCEDURE [app].[performance_counters]
	@machinename NVARCHAR(200),@collection_id UNIQUEIDENTIFIER, @collection_time DATETIME2(7), @categoryname NVARCHAR(200), @countername NVARCHAR(200), @instancename NVARCHAR(200),@countervalue FLOAT

AS
BEGIN
    INSERT INTO [log].[performancecounters] VALUES(@collection_id,@collection_time,@categoryname,@countername,@instancename,@machinename,@countervalue);
    DECLARE @server_name NVARCHAR(200);
    SELECT @server_name = [vs].[server_name] FROM [setup].[v_servers] AS [vs] WHERE [vs].[server_name_fqdn] = @machinename
    EXEC app.[server_load] @server_name = @server_name, -- nvarchar(200)
    @categoryname = @categoryname, -- nvarchar(200)
    @countername = @countername, -- nvarchar(200)
    @instancename = @instancename, -- nvarchar(200)
    @countervalue = @countervalue -- float
END