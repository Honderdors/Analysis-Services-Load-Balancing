CREATE TABLE [setup].[system_global_variables] (
    [property_name]      NVARCHAR (100)  NOT NULL,
    [property_value]     NVARCHAR (4000)  NULL,
    [description]        NVARCHAR (200)  NULL,
    [property_timestamp] SMALLDATETIME   NULL,
    [LastUpdateBy]       NVARCHAR (1000) NULL,
    [Property_Path]      NVARCHAR (MAX)  NULL
);




GO


CREATE TABLE [log].[system_global_variables_audit] (
    [EntryDate]   DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [Action]      NVARCHAR (50)   NOT NULL,
    [RowID]       NVARCHAR (100)  NOT NULL,
    [ColumnValue] NVARCHAR (MAX)  NULL,
    [UserName]    NVARCHAR (1000) NOT NULL
);




GO

CREATE TRIGGER [setup].[Trigger_system_global_variables] ON [setup].[system_global_variables]
    FOR DELETE, INSERT, UPDATE
AS
    BEGIN
        SET NoCount ON
/*Collect data*/
		INSERT INTO [log].[system_global_variables_audit] 
		(
		--[EntryDate],  /*Default UTC*/
		[Action],		
		[RowID],		
		[ColumnValue],	
		[UserName]
		)		
		SELECT 'INSERT', [property_name],[property_value], SUSER_SNAME()
		FROM Inserted
		INSERT INTO [log].[system_global_variables_audit] 
		(
		--[EntryDate], /*Default UTC*/
		[Action],		
		[RowID],		
		[ColumnValue],	
		[UserName]
		)		
		SELECT 'DELETE', [property_name],[property_value], SUSER_SNAME()
		FROM Deleted
		SET NOCOUNT OFF
    END