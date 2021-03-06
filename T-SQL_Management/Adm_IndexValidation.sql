--Validacao dos Index
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
  JOIN sys.dm_db_index_operational_stats(db_id('DATABASE_NAME'),NULL, NULL, NULL) vwx 
    ON vwx.index_id = ix.index_id and ix.object_id = vwx.object_id
  JOIN sys.dm_db_index_physical_stats(db_id('DATABASE_NAME'), NULL, NULL, NULL , 'SAMPLED') vwy 
    ON vwy.index_id = ix.index_id and ix.object_id = vwy.object_id and vwy.partition_number = vwx.partition_number
  JOIN sys.dm_db_partition_stats PS 
    ON ps.index_id = vw.index_id and ps.object_id = vw.object_id
 WHERE vw.database_id = db_id('DATABASE_NAME')
   AND ix.type_desc = 'NONCLUSTERED'
 ORDER BY user_seeks ASC, user_scans ASC