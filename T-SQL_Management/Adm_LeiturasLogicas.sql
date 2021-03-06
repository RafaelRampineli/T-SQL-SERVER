--Consultas com maior numero de Leitura Logica e Plano de Execucao
SELECT TOP 30 WITH TIES
        total_logical_reads,
        last_logical_reads,
        min_logical_reads,
        max_logical_writes,
        sql_handle,
        plan_handle,
        query_hash,
        query_plan_hash,
        plan_generation_num,
        creation_time,
        last_execution_time,
        execution_count,
        total_physical_reads,
        total_logical_writes,
        total_elapsed_time,
        C.dbid,
        C.objectid,
        text,
        C.encrypted,
        query_plan
 FROM sys.dm_exec_query_stats as EQS
CROSS APPLY sys.dm_exec_sql_text(EQS.sql_handle) AS C
CROSS APPLY sys.dm_exec_query_plan(EQS.plan_handle) AS T
ORDER BY total_logical_reads DESC
GO