USE MASTER
GO

DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'WorkGroup_AG'

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
VERIFICAR SE O CLUSTER QUE IR� RECEBER O FAIOLVER EST� HEALTH AND UP (� POSS�VEL VERIFICAR ATRAV�S DO CLUSTER MANAGEMENT
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM sys.dm_hadr_cluster_members



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
EXECUTAR O COMANDO NA REPLICA SECUND�RIA QUE IR� ASSUMIR A FUN��O PRIM�RIA 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' FORCE_FAILOVER_ALLOW_DATA_LOSS;'  



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
QUANDO A ANTIGA REPLICA PRIM�RIA FICAR ONLINE, ELA IR� SUBIR COMO UMA REPLICA SECUND�RIA, POR�M OS DADOS N�O SER�O SINCRONIZADOS AUTOMATICAMENTE.
� NECESS�RIO APLICAR UM RESUME NO ALWAYSON DE CADA BASE DE DADOS 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER DATABASE ' + NAME + ' SET HADR RESUME;' 
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')




/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
	PODE OCORRER DA ANTIGA R�PLICA PRIM�RIA DEMORAR MUITO TEMPO PARA FICAR ONLINE. 
	ESSA DEMORA PODE IMPACTAR NO TANTO DE LOG QUE SER� ARMAZENADO E CAUSAR UM CRESCIMENTO DE ESPA�O UTILIZADO NOS DISCOS.
	
	ANALISAR A CONDI��O E CASO SEJA NECESS�RIO, REMOVER A(s) BASE DE DADOS DO AVAILABILITY GROUPS E REFAZER QUANDO A R�PLICA ESTIVER ONLINE.
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' REMOVE DATABASE ' + NAME + ';'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

