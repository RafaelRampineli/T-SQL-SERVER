--Apresenta consumo de procedures com plano de execução
SELECT d.object_id, DB_NAME(d.database_id), OBJECT_NAME(object_id, database_id) 'procname', c.query_plan AS Plan_Query,
    d.cached_time, d.last_execution_time, d.total_elapsed_time,
    d.total_elapsed_time/d.execution_count AS [avg_elapsed_time],
  d.total_logical_reads / d.execution_count avg_logical_reads,
  d.total_worker_time / d.execution_count avg_worker_time,
  d.total_logical_writes / d.execution_count avg_logical_writes,
 d.last_logical_reads,
    d.last_elapsed_time, d.execution_count, d.total_logical_reads,
 d.total_physical_reads, d.total_logical_writes, d.last_logical_Writes,d.last_worker_time,
 d.sql_handle,
 d.plan_handle
FROM sys.dm_exec_procedure_stats AS d
CROSS APPLY sys.dm_exec_query_plan(d.plan_handle) AS C
ORDER BY avg_worker_time DESC