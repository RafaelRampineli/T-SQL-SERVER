--Quantidade de Index na tabela
[SELECT x.id, x.table_name, x.Total_index, count(*) AS Total_column 
  FROM sys.columns cl 
  JOIN (SELECT ix.object_id AS id, tb.name AS table_name, count(ix.object_id) AS Total_index 
  FROM sys.indexes ix join sys.objects tb 
    ON tb.object_id = ix.object_id 
   AND tb.type = 'u' 
 GROUP BY ix.object_id, tb.name) x 
    ON x.id = cl.object_id 
 GROUP BY id, table_name, Total_index 
 ORDER BY 3 DESC