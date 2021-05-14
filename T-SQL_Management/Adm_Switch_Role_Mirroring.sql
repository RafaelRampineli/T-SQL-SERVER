/********************************************************************************************************************************************
	Descrição: Script para realizar o Switch Role do servidor Principal para o servidor Mirror. 
	Este script deve ser executando no servidor Principal e logo após, uma consulta SQL que está no final do script deve ser executada no novo Principal (antigo Mirror) 
	e seu resultado executado novamente. 

	Este script serve para manutençoes planejadas e os dois servidores devem estar em pleno funcionamento. 
	Nao utilizar este script em caso de desastres. Após o Failver , 
 
	Explicaçao: A primeira açao deste script é alterar todas as datanases para safety-mode, para que esta operaçao ocorra sem perda de dados. 
	Em seguida, devemos ativar o Failover de cada uma das databases.
	 Se o failover desta database falhar, provavelmente o Principal e o Mirror ainda estarao sincronizando, 
	 o script irá aguardar por um pequeno espaço de tempo para tentar novamente automaticamente. 
	 Ao realizar o Failover de cada database, sera necessário reativar o modo performance no novo Principal (antigo Mirror), caso isto nao ocorra, 
	 a performance no novo Principal será reduzida drasticamente.
************************************************************************************************************************************************/
USE [master]
GO

/**********************************************************************************************************************************************
						ALTERANDO TODAS AS DATABASES PARA SAFETY MODE
***********************************************************************************************************************************************/
DECLARE @command NVARCHAR(MAX);
DECLARE @dbname VARCHAR(MAX);
DECLARE @execucaoOK SMALLINT;
DECLARE cur_db_safety_mode CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
	SELECT 
	  'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER SAFETY FULL;' AS cmd,
	  DB_NAME(database_id) dbname
	FROM master.sys.database_mirroring 
	WHERE 1=1
	AND mirroring_guid IS NOT NULL
	AND mirroring_role_desc = 'PRINCIPAL'
	AND mirroring_safety_level_desc = 'OFF';
PRINT 'Alterando todas as databases para safety-mode...'
OPEN cur_db_safety_mode
FETCH NEXT FROM cur_db_safety_mode INTO @command, @dbname;
WHILE @@fetch_status = 0
BEGIN
	EXECUTE sp_executesql @statement=@command;
	PRINT 'Alteraçao safety-mode [OK] para database ['+@dbname+']'
	FETCH NEXT FROM cur_db_safety_mode INTO @command, @dbname;
END
CLOSE cur_db_safety_mode;  
DEALLOCATE cur_db_safety_mode;
/****************************************************************************************************************************************************
						REALIZAR FAILOVER DE CADA DATABASE
****************************************************************************************************************************************************/
DECLARE cur_db_failover CURSOR LOCAL FORWARD_ONLY STATIC READ_ONLY FOR
	SELECT 
	 'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER FAILOVER;' cmd,
		DB_NAME(database_id) dbname
	FROM master.sys.database_mirroring 
	WHERE 1=1
	AND mirroring_guid IS NOT NULL
	AND mirroring_role_desc = 'PRINCIPAL'
	AND mirroring_safety_level_desc = 'FULL'
	AND mirroring_state_desc = 'SYNCHRONIZED'
	ORDER BY DB_NAME(database_id);
OPEN cur_db_failover
FETCH NEXT FROM cur_db_failover INTO @command, @dbname
WHILE @@fetch_status = 0
BEGIN
	SET @execucaoOK = 1
	WHILE @execucaoOK != 0
	BEGIN
		EXECUTE @execucaoOK = sp_executesql @statement=@command;
		IF @execucaoOK = 0
			PRINT 'Failover da database ['+@dbname+'] foi realizado com sucesso!'
		ELSE
		BEGIN
			PRINT 'Nao foi possível fazer failover...Aguardando Mirror e Principal da database [' + @dbname + '] sincronizarem para tentarmos novamente...'
			WAITFOR DELAY '00:00:03' --Aguardar 3 segundos para tentar denovo...
		END
 
	END
	FETCH NEXT FROM cur_db_failover INTO @command, @dbname;
END
CLOSE cur_db_failover;
DEALLOCATE cur_db_failover;
PRINT 'Failover geral do servidor realizado com sucesso!'
PRINT 'ATENÇAO!! Altere o modo de execuçao para performance-mode no novo Principal!'
/******************************************************************************************************************************************************
							EXECUTAR O SQL ABAIXO NO NOVO PRINCIPAL
******************************************************************************************************************************************************/
--SELECT 
--  'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER SAFETY OFF;'
--  AS command_to_set_mirrored_database_to_use_synchronous_mirroring_mode
--FROM master.sys.database_mirroring 
--WHERE 1=1
--AND mirroring_guid IS NOT NULL
--AND mirroring_role_desc = 'PRINCIPAL'
--AND mirroring_safety_level_desc = 'FULL'
--ORDER BY DB_NAME(database_id);