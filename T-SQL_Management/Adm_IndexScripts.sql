--Scripts about Indexs
/****************************************************************************************************************
						QUANTIDADE DE INDEX DAS TABELAS
****************************************************************************************************************/
SELECT x.id, x.table_name, x.Total_index, count(*) AS Total_column 
  FROM sys.columns cl 
  JOIN (SELECT ix.object_id AS id, tb.name AS table_name, count(ix.object_id) AS Total_index 
  FROM sys.indexes ix join sys.objects tb 
    ON tb.object_id = ix.object_id 
   AND tb.type = 'u' 
 GROUP BY ix.object_id, tb.name) x 
    ON x.id = cl.object_id 
 GROUP BY id, table_name, Total_index 
 ORDER BY 3 DESC

/****************************************************************************************************************
						QUANTIDADE DE INDEX MISSING
****************************************************************************************************************/
SELECT TOP 1000 (avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)) as Impacto, 
       migs.group_handle, mid.index_handle, migs.user_seeks,migs.user_scans, mid.object_id, mid.statement, 
       mid.equality_columns, mid.inequality_columns, mid.included_columns 
 FROM sys.dm_db_missing_index_group_stats AS migs 
 JOIN sys.dm_db_missing_index_groups AS mig 
   ON migs.group_handle = mig.index_group_handle 
 JOIN sys.dm_db_missing_index_details AS mid 
   ON mig.index_handle = mid.index_handle 
  AND database_id = db_id('DB_NAME')  -- –and mid.object_id = object_id(‘tabela’) — se desejar ver apenas para uma tabela específica order by Impacto DESC;
ORDER BY user_seeks DESC

/****************************************************************************************************************
						QUANTIDADE DE INDEX NÃO UTILIZADOS
****************************************************************************************************************/
SELECT tb.name AS Table_Name, ix.name AS Index_Name, ix.type_desc, leaf_insert_count,leaf_delete_count, leaf_update_count, 
       nonleaf_insert_count ,nonleaf_delete_count, nonleaf_update_count 
  FROM sys.dm_db_index_usage_stats vw 
  JOIN sys.objects tb 
    ON tb.object_id = vw.object_id 
  JOIN sys.indexes ix on ix.index_id = vw.index_id 
   AND ix.object_id = tb.object_id 
  JOIN sys.dm_db_index_operational_stats(db_id('DB_NAME'), Null, NULL, NULL) vwx 
    ON vwx.object_id = tb.object_id 
   AND vwx.index_id = ix.index_id 
 WHERE vw.database_id = db_id('DB_NAME') 
   AND vw.user_seeks = 0 and vw.user_scans = 0 
   AND vw.user_lookups = 0 
   AND vw.system_seeks = 0 
   AND vw.system_scans = 0 
   AND vw.system_lookups = 0
 ORDER BY leaf_insert_count DESC, tb.name ASC

/****************************************************************************************************************
						INDEX VALIDATIONS
****************************************************************************************************************/
SELECT tb.name AS [Table],
	   ix.NAME AS [Index], 
	   ix.type_desc AS [Type], 
	   vw.user_seeks,
	   vw.user_scans,
	   vw.user_lookups,
	   CONVERT(REAL,ps.in_row_used_page_count) * 8192 / 1024 / 1024 AS Total_Indice_Usado_MB,
	   CONVERT(REAL,ps.in_row_reserved_page_count) * 8192 / 1024 / 1024 AS Total_Indice_Reservado_MB, 
	   fill_factor,
	   vw.last_user_seek,  
	   vw.last_user_scan,  
	   vw.user_updates AS 'Total_User_Escrita',
       (vw.user_scans + vw.user_seeks + vw.user_lookups) AS 'Total_User_Leitura' ,
	   ps.row_count
  FROM sys.dm_db_index_usage_stats vw
  JOIN sys.objects tb 
    ON tb.object_id = vw.object_id 
  JOIN sys.indexes ix 
    ON ix.index_id = vw.index_id and ix.object_id = vw.object_id
  JOIN sys.dm_db_index_operational_stats(db_id('DB_NAME'),NULL, NULL, NULL) vwx 
    ON vwx.index_id = ix.index_id and ix.object_id = vwx.object_id
  JOIN sys.dm_db_index_physical_stats(db_id('DB_NAME'), NULL, NULL, NULL , 'SAMPLED') vwy 
    ON vwy.index_id = ix.index_id and ix.object_id = vwy.object_id and vwy.partition_number = vwx.partition_number
  JOIN sys.dm_db_partition_stats PS 
    ON ps.index_id = vw.index_id and ps.object_id = vw.object_id
 WHERE vw.database_id = db_id('DB_NAME')
   AND ix.type_desc = 'NONCLUSTERED'
 ORDER BY user_seeks ASC, user_scans ASC

/****************************************************************************************************************
						VOLUME WRITE/READ INDEXS
****************************************************************************************************************/
SELECT OBJECT_NAME(s.[object_id]) AS [Table Name] 
, i.name AS [Index Name] 
, i.index_id 
, user_updates AS [Total Writes] 
, user_seeks + user_scans + user_lookups AS [Total Reads] 
, user_updates - ( user_seeks + user_scans + user_lookups ) AS [Difference] 
 FROM sys.dm_db_index_usage_stats AS s WITH ( NOLOCK ) 
INNER JOIN sys.indexes AS i WITH ( NOLOCK ) 
   ON s.[object_id] = i.[object_id] 
  AND i.index_id = s.index_id 
WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1 
  AND s.database_id = DB_ID() 
  AND user_updates > ( user_seeks + user_scans + user_lookups ) 
  AND i.index_id > 1 
ORDER BY [Difference] DESC , [Total Writes] DESC , [Total Reads] ASC; 