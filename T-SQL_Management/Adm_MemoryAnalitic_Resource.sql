-- Pool usage memory
SELECT pool_id  
     , Name  
     , min_memory_percent  
     , max_memory_percent  
     , max_memory_kb/1024 AS max_memory_mb  
	 , used_memory_kb/1024
     , (used_memory_kb/1024 * 100)  / target_memory_kb
     , target_memory_kb/1024 AS target_memory_mb  
FROM sys.dm_resource_governor_resource_pools  


-- space usage summary
SELECT SUM(unallocated_extent_page_count) AS FreePages,
    CAST(SUM(unallocated_extent_page_count)/128.0 AS decimal(9,2)) AS FreeSpaceMB,
    SUM(version_store_reserved_page_count) AS VersionStorePages,
    CAST(SUM(version_store_reserved_page_count)/128.0 AS decimal(9,2)) AS VersionStoreMB,
    SUM(internal_object_reserved_page_count) AS InternalObjectPages,
    CAST(SUM(internal_object_reserved_page_count)/128.0 AS decimal(9,2)) AS InternalObjectsMB,
    SUM(user_object_reserved_page_count) AS UserObjectPages,
    CAST(SUM(user_object_reserved_page_count)/128.0 AS decimal(9,2)) AS UserObjectsMB
  FROM sys.dm_db_file_space_usage;
  
  
-- Obtaining the space consumed by internal objects in all currently running tasks in each session
SELECT session_id,
  SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
  SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count
FROM sys.dm_db_task_space_usage
GROUP BY session_id;

-- Obtaining the space consumed by internal objects in the current session for both running and completed tasks
SELECT R2.session_id,
  R1.internal_objects_alloc_page_count
  + SUM(R2.internal_objects_alloc_page_count) AS session_internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count
  + SUM(R2.internal_objects_dealloc_page_count) AS session_internal_objects_dealloc_page_count
FROM sys.dm_db_session_space_usage AS R1
INNER JOIN sys.dm_db_task_space_usage AS R2 ON R1.session_id = R2.session_id
GROUP BY R2.session_id, R1.internal_objects_alloc_page_count,
  R1.internal_objects_dealloc_page_count;;  