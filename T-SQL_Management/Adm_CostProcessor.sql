--Consultas que mais consomem processamento Servidor
SELECT TOP 10 (total_worker_time/execution_count) / 1000 AS [Avg CPU Time ms], SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
       ((CASE qs.statement_end_offset
         WHEN -1 THEN DATALENGTH(st.text)ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text,
       execution_count,last_execution_time, last_worker_time / 1000 as last_worker_time,  min_worker_time / 1000 as min_worker_time, 
       max_worker_time / 1000 as max_worker_time, total_physical_reads,last_physical_reads, min_physical_reads, max_physical_reads, 
       total_logical_writes,last_logical_writes, min_logical_writes, max_logical_writes, query_plan
 FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, DEFAULT, DEFAULT) AS qp
ORDER BY 1 DESC