--Leituras logicas procedure para comparativo
SELECT d.object_id, d.database_id, OBJECT_NAME(object_id, database_id) 'procname', 
    d.cached_time, d.last_execution_time, d.total_elapsed_time,
    d.total_elapsed_time/d.execution_count AS [avg_elapsed_time],
  d.total_logical_reads / d.execution_count avg_logical_reads,
  d.total_worker_time / d.execution_count avg_worker_time,
  d.total_logical_writes / d.execution_count avg_logical_writes,
 d.last_logical_reads,
    d.last_elapsed_time, d.execution_count, d.total_logical_reads,
 d.total_physical_reads, d.total_logical_writes, d.last_logical_Writes,d.last_worker_time
FROM sys.dm_exec_procedure_stats AS d
ORDER BY total_elapsed_time DESC