--Consultas em execução com Individual Query (Etapa que está executando)
IF OBJECT_ID('tempdb..#RESULT') IS NOT NULL
BEGIN
    DROP TABLE #RESULT
END

; WITH CPU
AS 
(
SELECT [Spid] = er.session_Id
, start_time
, Hostname
, loginame
, blocking_session_id
, blocked
, [Database] = DB_NAME(sp.dbid)
, [Wait] = wait_type
, [last_wait_type] = last_wait_type
, [Status] = er.status
, [Command] = er.command
, [cpu_time] = cpu_time
, [CPU_CUMULATIVO] = sp.CPU
, [total_elapsed_time] = total_elapsed_time
, [ObjectName] = object_name(qt.objectid,qt.dbid)
, [Individual Query] = SUBSTRING (qt.text,
er.statement_start_offset/2,
(CASE WHEN er.statement_end_offset = -1
THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
ELSE er.statement_end_offset END -
er.statement_start_offset)/2)
,[Parent Query] = qt.text
,[External Query] = qt2.text
--, Program = program_name
, percent_complete
, requested_memory_kb
, granted_memory_kb
, used_memory_kb
, max_used_memory_kb
, ideal_memory_kb
, t.task_internal_objects_alloc_page_count
, t.task_internal_objects_dealloc_page_count
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
WHERE er.session_Id > 0 --> 50-- Ignore system spids.
AND er.session_Id NOT IN (@@SPID) -- Ignore this current statement.
)
SELECT * 
INTO #RESULT
FROM CPU

/*******************************************************************************************************************************************************************************
													RETORNA OS DADOS POR PROCESSO
*******************************************************************************************************************************************************************************/
SELECT	  Spid, Start_Time, loginame, Blocking_Session_id, blocked
		, [Database], ObjectName, CPU_CUMULATIVO, cpu_time, [total_elapsed_time], Status, Command, wait, Last_wait_type, percent_complete
		, CAST(CPU_CUMULATIVO * 1.0 / SUM(CPU_CUMULATIVO) OVER() * 100.0 AS DECIMAL(5, 2)) AS Percent_CPU_Usage
		--, [Individual Query], [Parent Query], [External Query]
		--, requested_memory_kb, granted_memory_kb, used_memory_kb, max_used_memory_kb, ideal_memory_kb
		--, task_internal_objects_alloc_page_count, task_internal_objects_dealloc_page_count 		
		, Hostname
FROM #RESULT
order by CAST(CPU_CUMULATIVO * 1.0 / SUM(CPU_CUMULATIVO) OVER() * 100.0 AS DECIMAL(5, 2)) desc


/*******************************************************************************************************************************************************************************
													RETORNA OS DADOS AGRUPADO POR LOGIN x CPU ACUMULADO
*******************************************************************************************************************************************************************************/
;WITH CPU_LOGIN
AS
(
	SELECT loginame as Login,  SUM(CPU_CUMULATIVO) CPU
	FROM #RESULT
	group by loginame
) 
SELECT Login, CAST(CPU * 1.0 / SUM(CPU) OVER() * 100.0 AS DECIMAL(5, 2)) AS CPU 
FROM CPU_LOGIN
ORDER BY CPU desc



--Use tempdb

--SELECT *, (total_log_size_in_bytes - used_log_space_in_bytes)*1.0/1024/1024 AS [free log space in MB]  
--FROM sys.dm_db_log_space_usage; 


