--Selects de busca em registros de memorias
SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Buffer Manager%'
AND [counter_name] = 'Buffer cache hit ratio'

SELECT (a.cntr_value * 100.0 / b.cntr_value) as BufferCacheHitRatio
FROM sys.dm_os_performance_counters  a
JOIN  (SELECT cntr_value,OBJECT_NAME 
    FROM sys.dm_os_performance_counters  
    WHERE counter_name = 'Buffer cache hit ratio base'
        AND OBJECT_NAME = 'SQLServer:Buffer Manager') b ON  a.OBJECT_NAME = b.OBJECT_NAME
WHERE a.counter_name = 'Buffer cache hit ratio'
AND a.OBJECT_NAME = 'SQLServer:Buffer Manager'


SELECT object_name, counter_name, cntr_value
FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Buffer Manager%'
AND [counter_name] = 'Page life expectancy'


select counter_name ,cntr_value,cast((cntr_value/1024.0)/1024.0 as numeric(8,2)) as Gb
from sys.dm_os_performance_counters
where counter_name like '%server_memory%';


SELECT DB_NAME(database_id) AS [Database Name],
COUNT(*) * 8/1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 4 -- exclude system databases
AND database_id <> 32767 -- exclude ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC;


SELECT [cntr_value] 
FROM sys.dm_os_performance_counters 
WHERE [object_name] LIKE '%Memory Manager%' 
AND [counter_name] = 'Memory Grants Pending' 

SELECT * FROM sys.dm_exec_query_memory_grants WHERE grant_time IS NULL 

SELECT ROUND(CAST(A.cntr_value1 AS NUMERIC) /
CAST(B.cntr_value2 AS NUMERIC),3) AS Buffer_Cache_Hit_Ratio
FROM ( SELECT cntr_value AS cntr_value1
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio'
) AS A,
(SELECT cntr_value AS cntr_value2
FROM sys.dm_os_performance_counters
WHERE object_name = 'SQLServer:Buffer Manager' AND counter_name = 'Buffer cache hit ratio base'
) AS B;


select * from sys.dm_os_memory_clerks
