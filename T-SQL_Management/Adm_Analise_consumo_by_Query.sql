SELECT s2.dbid,
    object_name ( s2.OBJECTID, s2.dbid) name, 
    (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 ,   
      ( (CASE WHEN statement_end_offset = -1   
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2)   
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,  
         cast(s3.query_plan as xml) query_plan,
    execution_count,   
    plan_generation_num,   
    last_execution_time ,     
    total_worker_time / execution_count avg_worker_time,   
    total_logical_reads / execution_count avg_logical_reads,   
    total_logical_writes / execution_count avg_logical_writes,
    total_elapsed_time / execution_count avg_elapsed_time,
    total_worker_time, 
    total_logical_reads,
    total_logical_writes,
    total_elapsed_time
    total_dop,
    (total_dop * 1.00 )/ execution_count avg_dop,
    total_grant_kb,
    total_grant_kb / execution_count avg_grant_kb,
    total_used_grant_kb,
    total_used_grant_kb / execution_count avg_used_grant_kb,
    total_ideal_grant_kb,
    total_ideal_grant_kb / execution_count avg_ideal_grant_kb,
    total_spills,
    total_spills / execution_count avg_spills
FROM sys.dm_exec_query_stats AS s1   
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s2
cross apply sys.dm_exec_text_query_plan (plan_handle, statement_start_offset, statement_end_offset) s3
where object_name ( s2.objectid, s2.dbid) = ''
ORDER BY total_elapsed_time DESC
