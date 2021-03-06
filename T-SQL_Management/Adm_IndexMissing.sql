--Index que poderiam ser interessante existir
SELECT TOP 1000 (avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)) as Impacto, 
       migs.group_handle, mid.index_handle, migs.user_seeks,migs.user_scans, mid.object_id, mid.statement, 
       mid.equality_columns, mid.inequality_columns, mid.included_columns 
 FROM sys.dm_db_missing_index_group_stats AS migs 
 JOIN sys.dm_db_missing_index_groups AS mig 
   ON migs.group_handle = mig.index_group_handle 
 JOIN sys.dm_db_missing_index_details AS mid 
   ON mig.index_handle = mid.index_handle 
  AND database_id = db_id('db_name')  -- –and mid.object_id = object_id(‘tabela’) — se desejar ver apenas para uma tabela específica order by Impacto DESC;
ORDER BY user_seeks DESC