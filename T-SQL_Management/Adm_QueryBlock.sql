--Consultas que estao regaçando o BD
SELECT 
 DB_NAME(database_id) "Database",
 sqltext.TEXT Consulta,
 req.session_id,
 req.status,
 req.command,
 req.cpu_time,
 req.total_elapsed_time,
 req.logical_reads,
 last_wait_type,
 wait_type,
 percent_complete
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
ORDER BY cpu_time DESC