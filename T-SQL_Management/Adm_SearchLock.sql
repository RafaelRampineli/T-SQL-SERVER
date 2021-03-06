--Varre Locks em um determinado tempo. Não executa quando banco estiver crash
CREATE TABLE #WaitResources( session_id INT, wait_type NVARCHAR(1000), wait_duration_ms INT, resource_description SYSNAME NULL, db_name NVARCHAR(1000),
			schema_name NVARCHAR(1000), object_name NVARCHAR(1000), index_name NVARCHAR(1000));
GO

DECLARE @WaitDelay VARCHAR(16), 
		@Counter   INT, 
		@MaxCount  INT, 
		@Counter2  INT

SELECT @Counter = 0, @MaxCount = 600, @WaitDelay = '00:00:00.100'-- 600x.1=60 seconds
SET NOCOUNT ON;

WHILE @Counter < @MaxCount
BEGIN
	INSERT INTO #WaitResources
		( session_id, wait_type, wait_duration_ms, resource_description )--, db_name, schema_name, object_name, index_name)
	SELECT wt.session_id, wt.wait_type, wt.wait_duration_ms, wt.resource_description
	FROM sys.dm_os_waiting_tasks wt
	WHERE wt.wait_type LIKE 'PAGELATCH%' AND wt.session_id <> @@SPID
	--select * from sys.dm_os_buffer_descriptors
	SET @Counter = @Counter + 1
	WAITFOR DELAY @WaitDelay;
END;
--select * from #WaitResources
UPDATE #WaitResources
  SET db_name = DB_NAME(bd.database_id), schema_name = s.name, object_name = o.name, index_name = i.name
FROM #WaitResources wt
JOIN sys.dm_os_buffer_descriptors bd ON bd.database_id = SUBSTRING(wt.resource_description, 0, CHARINDEX(':', wt.resource_description)) AND bd.
file_id = SUBSTRING(wt.resource_description, CHARINDEX(':', wt.resource_description) + 1, CHARINDEX(':', wt.resource_description, CHARINDEX(':', wt.
resource_description) + 1) - CHARINDEX(':', wt.resource_description) - 1) AND bd.page_id = SUBSTRING(wt.resource_description, CHARINDEX(':', wt.
resource_description, CHARINDEX(':', wt.resource_description) + 1) + 1, LEN(wt.resource_description) + 1) --AND wt.file_index > 0 AND wt.page_index > 0
JOIN sys.allocation_units au ON bd.allocation_unit_id = AU.allocation_unit_id
JOIN sys.partitions p ON au.container_id = p.partition_id
JOIN sys.indexes i ON p.index_id = i.index_id AND p.object_id = i.object_id
JOIN sys.objects o ON i.object_id = o.object_id
JOIN sys.schemas s ON o.schema_id = s.schema_id




--Agrupando por wait_type e db_name
SELECT wait_type, db_name, schema_name, object_name, index_name, SUM(wait_duration_ms)
[total_wait_duration_ms] FROM #WaitResources
GROUP BY wait_type, db_name, schema_name, object_name, index_name
ORDER BY db_name;


/* Por sessao
SELECT session_id, wait_type, db_name, schema_name, object_name, index_name,
SUM(wait_duration_ms) [total_wait_duration_ms] FROM #WaitResources
GROUP BY session_id, wait_type, db_name, schema_name, object_name, index_name;
*/

--DROP TABLE #WaitResources;