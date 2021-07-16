USE MASTER
GO

DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'AG_Golsat'

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
VERIFICAR SE O CLUSTER QUE IR� RECEBER O FAIOLVER EST� HEALTH AND UP (� POSS�VEL VERIFICAR ATRAV�S DO CLUSTER MANAGEMENT
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM sys.dm_hadr_cluster_members


/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
EXECUTAR O COMANDO NA REPLICA SECUND�RIA QUE IR� ASSUMIR A FUN��O PRIM�RIA 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' FORCE_FAILOVER_ALLOW_DATA_LOSS;'  



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
PODE OCORRER DE ALGUMA BASE QUE N�O ESTAVA SINCRONIZADA NO MOMENTO DO FAILOVER FORCED ENTRAR NO STATUS DE RECOVERING/SUSPECT. 
ESSE � UM CEN�RIO CA�TICO E ALGUMAS ABORDAGENS PODEM SER REALIZADAS:
https://docs.microsoft.com/pt-br/troubleshoot/sql/availability-groups/alwayson-availability-databases-recovery-pending-suspect
----------------------------------------------------------------------------------------------------------------------------------------------------------- */

SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' REMOVE DATABASE ' + NAME + ';'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

SELECT 'ALTER DATABASE ' + NAME + ' SET EMERGENCY;'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

SELECT 'ALTER DATABASE ' + NAME + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

SELECT 'DBCC CHECKDB ('+NAME+', REPAIR_ALLOW_DATA_LOSS);'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

SELECT 'ALTER DATABASE ' + NAME + ' SET MULTI_USER;'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

SELECT 'ALTER DATABASE ' + NAME + ' SET ONLINE;'
FROM sys.databases
WHERE NAME NOT IN ('master', 'tempdb', 'model','msdb')

/*
AP�S A EXECU��O DOS COMANDOS E A BASE ESTIVER DISPONIVEL PARA ACESSO, SER� NECESS�RIO ALGUMAS ETAPAS:
1. ALTERAR A BASE PARA MODO RECOVERY FULL;
2. REALIZAR UM BACKUP FULL;
3. REALIZAR UM BACKUP TRANSACIONAL;
4. ADICIONAR A BASE DE VOLTA AO AVAILABILITY GROUP;
5. ADICIONAR A BASE DE VOLTA AO AVAILABLITITY GROUP NA REPLICA SECUND�RIA;
*/


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

