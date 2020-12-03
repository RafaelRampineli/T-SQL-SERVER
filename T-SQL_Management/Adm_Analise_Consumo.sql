IF OBJECT_ID('tempdb..#analiseAnterior') IS NOT NULL DROP TABLE #analiseAnterior

SELECT d.object_id, d.database_id, OBJECT_NAME(object_id, database_id) 'procname',
    d.cached_time,
    d.total_elapsed_time,
    d.total_worker_time,
    d.execution_count, 
    d.total_logical_reads,
    d.total_physical_reads, 
    d.total_logical_writes
INTO #analiseAnterior
FROM sys.dm_exec_procedure_stats AS d


WAITFOR DELAY '00:00:20';

WITH analisePosterior AS
    (SELECT d.object_id, d.database_id, OBJECT_NAME(object_id, database_id) 'procname', t.text sqlText,
        d.cached_time,
        d.total_elapsed_time,
        d.total_worker_time,
        d.execution_count, 
        d.total_logical_reads,
        d.total_physical_reads, 
        d.total_logical_writes
    FROM sys.dm_exec_procedure_stats AS d
    cross apply sys.dm_exec_sql_text(d.sql_handle) t)
SELECT ap.database_id, ap.procname, sqlText, ap.cached_time,
        ap.total_elapsed_time - aa.total_elapsed_time total_elapsed_time,
        ap.execution_count - aa.execution_count execution_count,
        ap.total_worker_time - aa.total_worker_time total_worker_time,
        ap.total_logical_reads - aa.total_logical_reads total_logical_reads,
        ap.total_logical_writes - aa.total_logical_writes total_logical_writes,
        CONVERT(NUMERIC(10,2),COALESCE(((ap.total_worker_time - aa.total_worker_time) * 100.00) / NULLIF(SUM(ap.total_worker_time - aa.total_worker_time) OVER (),0),0)) percent_workertime
FROM #analiseAnterior aa
INNER JOIN analisePosterior ap ON aa.object_id = ap.object_id
                                AND aa.cached_time = ap.cached_time
ORDER BY ap.total_worker_time - aa.total_worker_time DESC