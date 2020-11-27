/* RESTORE PARCIAL

RESTORE DATABASE [<Database>]
FILEGROUP = '<File_Group_name>'
FROM DISK =	'<Directory.bak>'
WITH FILE = 1,
NORECOVERY, PARTIAL

Aplicar Logs depois!
----

RESTORE DATABASE [db_name] FROM DISK = '\\dbbkp.gs.interno\backup\DB_diario\backup_SQL\Golsat\Golsat_backup_2020_04_25_230001_8079262.bak' WITH NORECOVERY
WITH MOVE 'MODELO_NOVO_Data' TO N'/mnt/db_files/SANKHYA_TESTE/EXPRESS_TESTE2.mdf', 
	 MOVE 'MODELO_NOVO_Log' TO N'/mnt/db_files/SANKHYA_TESTE/EXPRESS_TESTE2.LDF', 

----- 
Verificar os files que existem no backup
RESTORE FILELISTONLY FROM DISK = '\\bkp-onsite.gs.interno\db\backup\DB_diario\backup_SQL\GolsatWebCharts\GolsatWebCharts_backup_2020_10_24_230001_9055501.bak'
GO

*/

DECLARE @databaseName sysname
DECLARE @backupStartDate DATETIME
DECLARE @backupEndDate DATETIME
DECLARE @backup_set_id_start INT
DECLARE @backup_set_id_end INT 
DECLARE @UseDIFFBackup BIT = 0

-- Configura o nome do Backup
SET @databaseName		= 'DATABASE' 
SET @backupStartDate	= NULL -- Valor NULL Considera ultimo Backup Full Realizado / Quando Preenchido busca último FULL antes da respectiva Data
SET @backupEndDate		= DATEADD(YEAR,1,GETDATE())


-- Recupera o Ultimo Backup Full realizado para ser o Inicio do RESTORE
SELECT @backup_set_id_start = MAX(backup_set_id) 
FROM msdb.dbo.backupset 
WHERE database_name = @databaseName AND type = 'D' -- Tipo do Backup: D = Backup Full
AND backup_start_date <= COALESCE(@backupStartDate,GETDATE())


-- Recupera o PROXIMO Backup Full executado APÓS o obtido para inicio do RESTORE
--SELECT @backup_set_id_end = MIN(backup_set_id) 
--FROM msdb.dbo.backupset 
--WHERE database_name = @databaseName AND type = 'D' -- Tipo do Backup: D = Backup Full
--AND ((backup_start_date > @backupStartDate) OR backup_set_id > @backup_set_id_start )


-- Se não foi identificado nenhum Backup Full, seta um ID para controle 
IF (@backup_set_id_end IS NULL)
BEGIN
	SET @backup_set_id_end = 999999999 
END

-- Seleciona o Registro do Backup Full
SELECT	backup_set_id, 'FULL' AS Type, 'PRINT' + ' ''##### RESTAURANDO FULL DO DIA: ' + CONVERT(VARCHAR,backup_start_date,126) + ' #####''' +
		' RESTORE DATABASE ' + @databaseName + ' FROM DISK = ''' + mf.physical_device_name + ''' WITH NORECOVERY', backup_finish_date
FROM msdb.dbo.backupset b, 
msdb.dbo.backupmediafamily mf 
WHERE b.media_set_id = mf.media_set_id 
AND b.database_name = @databaseName 
AND b.backup_set_id = @backup_set_id_start 

UNION 

-- Seleciona o Registro dos Backups de LOG entre o Backup Full de Inicio até o Proximo Backup Full
SELECT	backup_set_id, 'LOG' AS Type, 'PRINT' + ' ''##### RESTAURANDO LOG DO DIA: ' + CONVERT(VARCHAR,backup_start_date,126) + ' #####''' +
		' RESTORE LOG ' + @databaseName + ' FROM DISK = ''' + mf.physical_device_name + ''' WITH NORECOVERY', backup_finish_date
FROM msdb.dbo.backupset b, 
msdb.dbo.backupmediafamily mf 
WHERE b.media_set_id = mf.media_set_id 
AND b.database_name = @databaseName 
AND b.backup_set_id >= @backup_set_id_start AND b.backup_set_id < @backup_set_id_end 
AND b.type = 'L'  -- Tipo do Backup: L = LOG

UNION 

SELECT	backup_set_id, 'DIFF' AS Type,  'PRINT' + ' ''##### RESTAURANDO DIFERENCIAL: ' + CONVERT(VARCHAR,backup_start_date,126) + ' #####''' +
		'RESTORE DATABASE ' + @databaseName + ' FROM DISK = ''' +  mf.physical_device_name + ''' WITH NORECOVERY', backup_finish_date
FROM    msdb.dbo.backupset b,
msdb.dbo.backupmediafamily mf
WHERE b.media_set_id = mf.media_set_id
AND b.database_name = @databaseName
AND b.backup_set_id >= @backup_set_id_start AND b.backup_set_id < @backup_set_id_end 
AND b.type = 'I'
AND @UseDIFFBackup = 1


UNION 

-- Gera um registro FAKE para fechar o restore e liberar a base
SELECT	999999999 AS backup_set_id, 'CLOSE' AS Type,  'PRINT' + ' ''##### CLOSING RESTORE' + ' #####''' +
		' RESTORE DATABASE ' + @databaseName + ' WITH RECOVERY', GETDATE() AS backup_finish_date
ORDER BY backup_set_id
