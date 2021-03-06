--Locks atualmente no DataBase
SELECT	DB_NAME(database_id) AS 'DB' ,
		wait_type,
		COUNT(*)
FROM  sys.dm_exec_requests
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS SqlText
--WHERE DB_NAME(database_id) = '[DATABASE_NAME]'
GROUP BY database_id, wait_type
ORDER BY 3 DESC