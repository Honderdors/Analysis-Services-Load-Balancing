CREATE TABLE [setup].[url_templates]
(
	[url_id] INT NOT NULL PRIMARY KEY,
	[url] NVARCHAR(max) DEFAULT('http://<server>/OLAP/msmdpump.dll')
)
