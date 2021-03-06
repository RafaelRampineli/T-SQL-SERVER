--Plano de execução de Procedures
SELECT cp.plan_handle, st.[text], OBJECT_NAME(objectid, dbid) AS 'procname'
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st