--Verifica Leitura no disco
SELECT DB_NAME(database_id) AS DatabaseName,
        FILE_ID,
        FILE_NAME(FILE_ID) AS NAME,
        D.io_stall_read_ms AS ReadsIOStall,
        D.num_of_reads AS NumsReads,
		D.num_of_writes AS NumWrites,
        CAST(D.io_stall_read_ms / (1.0 + num_of_reads) AS NUMERIC(10,1)) AS AvgReadsStall,
        io_stall_read_ms + io_stall_write_ms AS IOStalls,
        num_of_reads + num_of_writes AS TotalIO,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / (1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1)) AS AvgIOStall,
		io_stall
FROM sys.dm_io_virtual_file_stats(DB_ID(),NULL) AS D