USE MASTER
GO

DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'WorkGroup_AG'

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
VERIFICAR SE O CLUSTER QUE IRÁ RECEBER O FAIOLVER ESTÁ HEALTH AND UP (É POSSÍVEL VERIFICAR ATRAVÉS DO CLUSTER MANAGEMENT
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM sys.dm_hadr_cluster_members



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
EXECUTAR O COMANDO NA REPLICA SECUNDÁRIA QUE IRÁ ASSUMIR A FUNÇÃO PRIMÁRIA 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' FORCE_FAILOVER_ALLOW_DATA_LOSS;'  



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
QUANDO A ANTIGA REPLICA PRIMÁRIA FICAR ONLINE, ELA IRÁ SUBIR COMO UMA REPLICA SECUNDÁRIA, PORÉM OS DADOS NÃO SERÃO SINCRONIZADOS AUTOMATICAMENTE.
É NECESSÁRIO APLICAR UM RESUME NO ALWAYSON DE CADA BASE DE DADOS 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER DATABASE ' + NAME + ' SET HADR RESUME;' 
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')




/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
	PODE OCORRER DA ANTIGA RÉPLICA PRIMÁRIA DEMORAR MUITO TEMPO PARA FICAR ONLINE. 
	ESSA DEMORA PODE IMPACTAR NO TANTO DE LOG QUE SERÁ ARMAZENADO E CAUSAR UM CRESCIMENTO DE ESPAÇO UTILIZADO NOS DISCOS.
	
	ANALISAR A CONDIÇÃO E CASO SEJA NECESSÁRIO, REMOVER A(s) BASE DE DADOS DO AVAILABILITY GROUPS E REFAZER QUANDO A RÉPLICA ESTIVER ONLINE.
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' REMOVE DATABASE ' + NAME + ';'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

