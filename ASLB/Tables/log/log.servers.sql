CREATE TABLE [log].[servers]
(
    [entrytime] DATETIME2(7) NOT NULL,
    [server_id] INT NOT NULL,
    [server_offline] BIT NOT NULL
        DEFAULT (0),
    [server_offline_time] DATETIME2(7)
        DEFAULT (GETUTCDATE()),
    [server_online_time] DATETIME2(7)
        DEFAULT (GETUTCDATE()),
    [server_last_request_time] DATETIME2 NULL,
    [server_cpu] FLOAT NULL
        DEFAULT 0,
    [server_memory] FLOAT NULL
        DEFAULT 0,
    [server_connections] FLOAT NULL
        DEFAULT 0,[server_load_update_time] DATETIME2 NULL
);
