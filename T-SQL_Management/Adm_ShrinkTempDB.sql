--Executar script quando for necessário realizar Shrink no TEMPDB (EVITAR O USO DE SHRINK)
USE [tempdb]
GO

DECLARE @varMBFree INT
CREATE TABLE #tmpDrives (drive CHAR(1), MBFree INT)
INSERT INTO #tmpDrives
EXEC master..xp_fixeddrives
SELECT @varMBFree=MBFree FROM #tmpDrives WHERE drive = 'T'

PRINT @varMBFree

--IF @varMBFree < 1000000
BEGIN
   DECLARE @varDataHoraIni DATETIME = GETDATE(), @varDataHoraFim DATETIME 
  ;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
  )
  SELECT TSU.session_id,
        TSU.alloc_pages * 1.0 / 128 AS EspacoAlocadoMB,
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS SQL
       --EQP.query_plan
  INTO #tempDBProcessos
  FROM task_space_usage AS TSU 
  INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
      ON  TSU.session_id = ERQ.session_id
      AND TSU.request_id = ERQ.request_id
  OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
  OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
  WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL;

  declare @kill varchar(8000) = '';
  select @kill=@kill+'kill '+convert(varchar(5),session_id)+';'
    from #tempDBProcessos
  exec (@kill);
  --PRINT @kill

  -- Executar para cada um dos arquivos do tempdb
  DBCC SHRINKFILE (N'templog' , 0, NOTRUNCATE)
  DBCC SHRINKFILE (N'templog' , 0, TRUNCATEONLY)
  DBCC SHRINKFILE (N'tempdb' , 0, NOTRUNCATE)
  DBCC SHRINKFILE (N'tempdb' , 0, TRUNCATEONLY)

END

DROP TABLE #tmpDrives

SELECT name, physical_name AS current_file_location
FROM sys.master_files
where name like '%temp%'