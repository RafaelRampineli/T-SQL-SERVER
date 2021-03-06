--Index nunca utilizados pelo SGDB
SELECT tb.name AS Table_Name, ix.name AS Index_Name, ix.type_desc, leaf_insert_count,leaf_delete_count, leaf_update_count, 
       nonleaf_insert_count ,nonleaf_delete_count, nonleaf_update_count 
  FROM sys.dm_db_index_usage_stats vw 
  JOIN sys.objects tb 
    ON tb.object_id = vw.object_id 
  JOIN sys.indexes ix on ix.index_id = vw.index_id 
   AND ix.object_id = tb.object_id 
  JOIN sys.dm_db_index_operational_stats(db_id('db_name'), Null, NULL, NULL) vwx 
    ON vwx.object_id = tb.object_id 
   AND vwx.index_id = ix.index_id 
 WHERE vw.database_id = db_id('db_name') 
   AND vw.user_seeks = 0 and vw.user_scans = 0 
   AND vw.user_lookups = 0 
   AND vw.system_seeks = 0 
   AND vw.system_scans = 0 
   AND vw.system_lookups = 0
 ORDER BY leaf_insert_count DESC, tb.name ASC