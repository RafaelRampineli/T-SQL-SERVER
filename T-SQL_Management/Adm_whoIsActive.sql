--Consultas em execução com Individual Query (Etapa que está executando)
SELECT [Spid] = er.session_Id
, t.*
, loginame
, blocking_session_id
, blocked
, [Database] = DB_NAME(sp.dbid)
, [Wait] = wait_type
, [last_wait_type] = last_wait_type
, [Status] = er.status
, [Command] = er.command
, [cpu_time] = cpu_time
, [total_elapsed_time] = total_elapsed_time
, [Individual Query] = SUBSTRING (qt.text,
er.statement_start_offset/2,
(CASE WHEN er.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
ELSE er.statement_end_offset END -
er.statement_start_offset)/2)
,[Parent Query] = qt.text
,[External Query] = qt2.text
, Program = program_name
, Hostname
, start_time
, requested_memory_kb
, granted_memory_kb
, used_memory_kb
, max_used_memory_kb
, ideal_memory_kb
FROM sys.dm_exec_requests er
INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
INNER JOIN sys.dm_exec_connections CN ON CN.session_id = er.session_id
INNER JOIN sys.dm_exec_query_memory_grants MM ON MM.session_id = er.session_id
INNER JOIN (SELECT session_id,
			SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
			SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count
			FROM sys.dm_db_task_space_usage
			GROUP BY session_id
			) as t on t.session_id = er.session_Id
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle)as qt
CROSS APPLY sys.dm_exec_sql_text(cn.most_recent_sql_handle)as qt2
WHERE er.session_Id > 50-- Ignore system spids.
AND er.session_Id NOT IN (@@SPID) -- Ignore this current statement.
ORDER BY task_internal_objects_alloc_page_count desc, task_internal_objects_dealloc_page_count desc



--Use tempdb

--SELECT *, (total_log_size_in_bytes - used_log_space_in_bytes)*1.0/1024/1024 AS [free log space in MB]  
--FROM sys.dm_db_log_space_usage;  
