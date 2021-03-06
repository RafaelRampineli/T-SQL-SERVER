SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[proc_Monitora_CheckList]
as

BEGIN

DELETE FROM [dbo].[TabCheckListArquivoSQL]
WHERE DataExecucao < CONVERT(DATE,GETDATE()-30)

--DELETE FROM [dbo].[TabCheckListBackup]
--WHERE backup_start_date < CONVERT(DATE,GETDATE()-30)

DELETE FROM [dbo].[TabCheckListEspacodisco]
WHERE Data < CONVERT(DATE,GETDATE()-30)

DELETE FROM [dbo].[TabCheckListJobsFailed]
WHERE Run_Date < REPLACE(LEFT(CONVERT(varchar,GETDATE()-30,120),10),'-','')

DELETE FROM [dbo].[TabCheckListUtilizacaoLog]
WHERE Data < CONVERT(DATE,GETDATE()-30)

-- MONITORAMENTO ESPAÇO EM DISCO 
BEGIN

SET NOCOUNT ON

CREATE TABLE #dbspace 
(
	Id INT IDENTITY(1,1) PRIMARY KEY
  ,	name sysname
  , caminho VARCHAR(200)
  , tamanho VARCHAR(10)
  , drive VARCHAR(30)
)

CREATE TABLE [#espacodisco] 
(    
	Id INT IDENTITY(1,1) PRIMARY KEY
  , Drive VARCHAR(10)
  , [Tamanho (MB)] INT
  , [Usado (MB)] INT
  , [Livre (MB)] INT
  , [Livre (%)] INT
  , [Usado (%)] INT
  , [Ocupado SQL (MB)] INT
  , [Data] SMALLDATETIME
)


EXEC SP_MSForEachDB 'Use ? Insert into #dbspace Select Convert(Varchar(25),DB_Name())"Database",Convert(Varchar(60),FileName),Convert(Varchar(8),Size/128)"Size in MB",Convert(Varchar(30),Name) from SysFiles'

DECLARE   @hr INT
		, @fso INT
		, @mbtotal INT 
		, @TotalSpace INT 
		, @MBFree INT
		, @Percentage INT
		, @SQLDriveSize INT
		, @size FLOAT
		, @drive VARCHAR(1)
		, @fso_Method VARCHAR(255)

SET @mbTotal = 0

EXEC  @hr = master.dbo.sp_OACreate 'Scripting.FilesystemObject'
	, @fso OUTPUT

CREATE TABLE #space 
(
	drive CHAR(1)
  , mbfree INT
)

INSERT INTO #space 
  EXEC master.dbo.xp_fixeddrives

DECLARE CheckDrives 
CURSOR FOR SELECT drive,MBfree FROM #space

OPEN CheckDrives
FETCH NEXT FROM CheckDrives INTO @Drive,@MBFree

WHILE(@@FETCH_STATUS=0)
BEGIN
SET @fso_Method = 'Drives("' + @drive + ':").TotalSize'

SELECT @SQLDriveSize = SUM(CONVERT(INT,tamanho))
  FROM #dbspace 
 WHERE SUBSTRING(caminho,1,1)=@drive

EXEC @hr = sp_OAMethod 
	 @fso, 
	 @fso_method, 
	 @size OUTPUT
     
SET @mbtotal =  @size / (1024 * 1024)

INSERT INTO #espacodisco
VALUES ( @Drive+':'
	   , @MBTotal
	   , @MBTotal-@MBFree
	   , @MBFree
	   , (100 * ROUND(@MBFree,2) / ROUND(@MBTotal,2))
	   , (100 - 100 * ROUND(@MBFree,2) / ROUND(@MBTotal,2)),@SQLDriveSize, GETDATE())

FETCH NEXT FROM CheckDrives INTO @drive,@mbFree
END
CLOSE CheckDrives
DEALLOCATE CheckDrives

IF (OBJECT_ID('TabCheckListEspacodisco') IS NULL)  
--DROP TABLE _CheckList_Espacodisco
BEGIN

CREATE TABLE TabCheckListEspacodisco
(
	Id INT PRIMARY KEY IDENTITY(1,1)
  , Drive VARCHAR(10)
  , [Tamanho (MB)] INT
  , [Usado (MB)] INT
  , [Livre (MB)] INT
  , [Livre (%)] INT
  , [Usado (%)] INT
  , [Ocupado SQL (MB)] INT
  , [Data] SMALLDATETIME
)

INSERT INTO TabCheckListEspacodisco
SELECT  Drive
	  , [Tamanho (MB)]
	  , [Usado (MB)]
	  , [Livre (MB)]
	  , [Livre (%)]
	  , [Usado (%)]
	  , ISNULL ([Ocupado SQL (MB)],0) AS [Ocupado SQL (MB)]
	  , GETDATE() AS 'DATA EXECUÇÃO'
  FROM #espacodisco

END
ELSE
BEGIN

INSERT INTO dbo.TabCheckListEspacodisco
SELECT  Drive
	  , [Tamanho (MB)]
	  , [Usado (MB)]
	  , [Livre (MB)]
	  , [Livre (%)]
	  , [Usado (%)]
	  , ISNULL ([Ocupado SQL (MB)],0) AS [Ocupado SQL (MB)]
	  , GETDATE() AS 'DATA EXECUÇÃO'
  FROM #espacodisco

END

DROP TABLE #dbspace
DROP TABLE #space
DROP TABLE #espacodisco

END

-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MONITORAMENTO ARQUIVOS SQL

IF (OBJECT_ID('TabCheckListArquivoSQL') IS NOT NULL)  
BEGIN

INSERT INTO dbo.TabCheckListArquivoSQL
SELECT  CONVERT(VARCHAR, name) AS NAME 
	  , Filename
	  , CAST(Size * 8 AS BIGINT) / 1024.00 SIZE
	  , CASE WHEN  MaxSize = -1 THEN  -1 
			 ELSE  CAST(MaxSize  AS BIGINT)* 8 / 1024.00 
		END MAXSIZE
	  , CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10 THEN CAST(Growth AS VARCHAR) + ' %'
			 ELSE CAST (CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2)) AS VARCHAR) + ' MB'
		END Growth
	  , CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10 THEN (CAST(Size AS BIGINT) * 8 / 1024.00) * ((Growth/100.00) + 1)
			 ELSE (CAST(Size  AS BIGINT) * 8 / 1024.00) + CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2))
		END Proximo_Tamanho 
	  , CASE WHEN MaxSize = -1 THEN 'OK' 
             WHEN (CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10
			 THEN (CAST(Size AS BIGINT)* 8 / 1024.00) * ((Growth/100.00) + 1)
			 ELSE (CAST(Size AS BIGINT) * 8/ 1024.00) + CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2))
	    END ) < (CAST(MaxSize AS BIGINT) * 8/1024.00) THEN 'OK' ELSE 'PROBLEMA'
		END Situacao
	  , GETDATE()
 FROM master..sysaltfiles WITH(NOLOCK)
ORDER BY Situacao, Size DESC
END


IF (OBJECT_ID('TabCheckListArquivoSQL') IS NULL)  
--DROP TABLE TabCheckList_Dba_Arquivos_SQL
BEGIN

CREATE TABLE dbo.TabCheckListArquivoSQL 
(
  [Name] VARCHAR(250) 
, [FileName] VARCHAR(250) 
, [Size] BIGINT
, [MaxSize] BIGINT
, Growth VARCHAR(100)
, Proximo_Tamanho BIGINT
, Situacao VARCHAR(15)
, DataExecucao DATETIME
)

INSERT INTO dbo.TabCheckListArquivoSQL
SELECT  CONVERT(VARCHAR, name) AS NAME 
	  , Filename
	  , CAST(Size * 8 AS BIGINT) / 1024.00 SIZE
	  , CASE WHEN  MaxSize = -1 THEN  -1 
			 ELSE  CAST(MaxSize  AS BIGINT)* 8 / 1024.00 
		END MAXSIZE
	  , CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10 THEN CAST(Growth AS VARCHAR) + ' %'
			 ELSE CAST (CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2)) AS VARCHAR) + ' MB'
		END Growth
	  , CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10 THEN (CAST(Size AS BIGINT) * 8 / 1024.00) * ((Growth/100.00) + 1)
			 ELSE (CAST(Size  AS BIGINT) * 8 / 1024.00) + CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2))
		END Proximo_Tamanho 
	  , CASE WHEN MaxSize = -1 THEN 'OK' 
             WHEN (CASE WHEN SUBSTRING(CAST(Status AS VARCHAR),1,2) = 10
			 THEN (CAST(Size AS BIGINT)* 8 / 1024.00) * ((Growth/100.00) + 1)
			 ELSE (CAST(Size AS BIGINT) * 8/ 1024.00) + CAST((Growth * 8 )/1024.00 AS NUMERIC(15,2))
	    END ) < (CAST(MaxSize AS BIGINT) * 8/1024.00) THEN 'OK' ELSE 'PROBLEMA'
		END Situacao
	  , GETDATE()      
 FROM master..sysaltfiles WITH(NOLOCK)
ORDER BY Situacao, Size DESC

END

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MONITORAMENTO ARQUIVOS LOG


--PROCEDURE MONITORA LOG CRIAR PROCEDURE 
--CREATE PROCEDURE [dbo].[proc_CheckList_Verifica_Utilizacao_Log]
--AS
--BEGIN

--/*MONITORARMENTO DOS ARQUIVOS DE LOG  - RAFAEL  02.07.2014*/

--DBCC SQLPERF (LOGSPACE)
--END
--GO

CREATE TABLE #TEMP
(
    Nm_Database VARCHAR(50)
  , Log_Size NUMERIC(15,2)
  , [Log_Space_Used(%)] NUMERIC(15,2)
  , status_log INT 
)

IF (OBJECT_ID('TabCheckListUtilizacaoLog') IS NULL)  
--DROP TABLE TabCheckList_Dba_Utilizacao_Log

BEGIN
CREATE TABLE dbo.TabCheckListUtilizacaoLog
(
    ID INT PRIMARY KEY IDENTITY(1,1)	
  , Nm_Database VARCHAR(50)
  , Log_Size NUMERIC(15,2)
  , [Log_Space_Used(%)] NUMERIC(15,2)
  , status_log INT 
  , Data datetime
)

INSERT #TEMP
EXEC dbo.proc_CheckList_Verifica_Utilizacao_Log

INSERT INTO dbo.TabCheckListUtilizacaoLog
SELECT *, GETDATE() FROM #TEMP

END
ELSE 
BEGIN

INSERT #TEMP
EXEC dbo.proc_CheckList_Verifica_Utilizacao_Log

INSERT INTO dbo.TabCheckListUtilizacaoLog
SELECT *, GETDATE() FROM #TEMP

END

DROP TABLE #TEMP


---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MONITORAMENTO BACKUPS



IF (OBJECT_ID('TabCheckListBackup') IS NULL)  
--DROP TABLE TabCheckList_Backup
BEGIN
CREATE TABLE dbo.TabCheckListBackup
(
    ID INT PRIMARY KEY IDENTITY(1,1)
  , database_name NVARCHAR(256)
  , name NVARCHAR(256)
  , backup_start_date DATETIME
  , tempo INT 
  , server_name NVARCHAR(256)
  , recovery_model NVARCHAR(120)
  , tamanho NUMERIC(15,2)
)
DECLARE @Dt_Referencia DATETIME

SELECT @Dt_Referencia = CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME) -- Hora zerada

INSERT dbo.TabCheckListBackup
SELECT  database_name
	  , name,Backup_start_date
	  , DATEDIFF(mi,Backup_start_date,Backup_finish_date) [tempo (min)]
	  , server_name,recovery_model
	  , CAST(backup_size/1024/1024 AS NUMERIC(15,2)) [Tamanho (MB)]
  FROM msdb.dbo.backupset B
 INNER JOIN msdb.dbo.backupmediafamily BF 
    ON B.media_set_id = BF.media_set_id
 WHERE Backup_start_date >= DATEADD(hh, 0 ,@Dt_Referencia - 1 ) --backups realizados a partir das 18h de ontem
   AND Backup_start_date < DATEADD (DAY, 0, @Dt_Referencia)
  -- AND type = 'D'

END
ELSE
BEGIN

SELECT @Dt_Referencia = CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME) -- Hora zerada

INSERT dbo.TabCheckListBackup
SELECT  database_name
	  , name,Backup_start_date
	  , DATEDIFF(mi,Backup_start_date,Backup_finish_date) [tempo (min)]
	  , server_name,recovery_model
	  , CAST(backup_size/1024/1024 AS NUMERIC(15,2)) [Tamanho (MB)]
  FROM msdb.dbo.backupset B
 INNER JOIN msdb.dbo.backupmediafamily BF 
    ON B.media_set_id = BF.media_set_id
 WHERE Backup_start_date >=  DATEADD(hh, 0 ,@Dt_Referencia - 1 ) --backups realizados a partir das 18h de ontem
   AND Backup_start_date < DATEADD (DAY, 0, @Dt_Referencia)
  -- AND type = 'D'
   
END 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- MONITORAMENTO JOBS QUE FALHARAM


IF OBJECT_ID('Tempdb..#Result_History_Jobs') IS NOT NULL    
DROP TABLE #Result_History_Jobs

CREATE TABLE #Result_History_Jobs
(
    Instance_Id INT
  , Job_Id VARCHAR(255)
  , Job_Name VARCHAR(255)
  , Step_Id INT 
  , Step_Name VARCHAR(255)
  , Sql_Message_Id INT 
  , Sql_Severity INT 
  , SQl_Message VARCHAR(4000)
  , Run_Status INT
  , Run_Date INT
  , Run_Time INT
  , Run_Duration INT
  , Operator_Emailed VARCHAR(255)
  , Operator_NetSent VARCHAR(255)
  , Operator_Paged VARCHAR(255)
  , Retries_Attempted INT
  , Nm_Server VARCHAR(100)
)

DECLARE @hoje VARCHAR (8)
DECLARE @ontem VARCHAR (8)
DECLARE @ontemInt INT
SET @ontem = CONVERT(VARCHAR(8),(DATEADD (DAY, -1, GETDATE())),112)
SET @ontemInt = CONVERT(INT,@ontem)


INSERT INTO #Result_History_Jobs
EXEC msdb.dbo.SP_HELP_JOBHISTORY
			  @mode = 'FULL' 
			, @start_run_date = @ontemInt

IF (OBJECT_ID('TabCheckListJobsFailed') IS NOT NULL)  

BEGIN

  INSERT INTO TabCheckListJobsFailed
  SELECT * FROM #Result_History_Jobs
   WHERE Run_Date = CONVERT(VARCHAR(8),(DATEADD (DAY, -1, GETDATE())),112)
     AND Run_Status = 0

END

ELSE
BEGIN

  SELECT  *   
    INTO TabCheckListJobsFailed
    FROM #Result_History_Jobs
   WHERE Run_Date = CONVERT(VARCHAR(8),(DATEADD (DAY, -1, GETDATE())),112)
     AND Run_Status = 0
   ORDER BY Run_Date

END

DROP TABLE #Result_History_Jobs

end

