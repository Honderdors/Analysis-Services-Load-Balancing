CREATE NONCLUSTERED INDEX [NCI_performancecounters_1]
ON [log].[performancecounters] ([collection_time],[machinename])
INCLUDE ([performancecounters_id],[collection_id],[categoryname],[countername],[instancename],[countervalue])
