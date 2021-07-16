USE MASTER
GO

<<<<<<< HEAD
DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'AG_Golsat'
=======
DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'AG_Name'
>>>>>>> 8422f51c973655b14ef840885e33f280d6109d04

/*-----------------------------------------------------------------------------------------------------------------------------------------------------------
VERIFICAR SE O CLUSTER QUE IRÁ RECEBER O FAIOLVER ESTÁ HEALTH AND UP (É POSSÍVEL VERIFICAR ATRAVÉS DO CLUSTER MANAGEMENT
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM sys.dm_hadr_cluster_members


/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
EXECUTAR O COMANDO NA REPLICA SECUNDÁRIA QUE IRÁ ASSUMIR A FUNÇÃO PRIMÁRIA 
-----------------------------------------------------------------------------------------------------------------------------------------------------------*/
SELECT 'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' FORCE_FAILOVER_ALLOW_DATA_LOSS;'  



/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
<<<<<<< HEAD
PODE OCORRER DE ALGUMA BASE QUE N�O ESTAVA SINCRONIZADA NO MOMENTO DO FAILOVER FORCED ENTRAR NO STATUS DE RECOVERING/SUSPECT. 
ESSE � UM CEN�RIO CA�TICO E ALGUMAS ABORDAGENS PODEM SER REALIZADAS:
=======
PODE OCORRER DE ALGUMA BASE QUE NÃO ESTAVA SINCRONIZADA NO MOMENTO DO FAILOVER FORCED ENTRAR NO STATUS DE RECOVERING/SUSPECT. 
ESSE É UM CENÁRIO CAÓTICO E ALGUMAS ABORDAGENS PODEM SER REALIZADAS:
>>>>>>> 8422f51c973655b14ef840885e33f280d6109d04
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
<<<<<<< HEAD
AP�S A EXECU��O DOS COMANDOS E A BASE ESTIVER DISPONIVEL PARA ACESSO, SER� NECESS�RIO ALGUMAS ETAPAS:
=======
APÓS A EXECUÇÃO DOS COMANDOS E A BASE ESTIVER DISPONIVEL PARA ACESSO, SERÁ NECESSÁRIO ALGUMAS ETAPAS:
>>>>>>> 8422f51c973655b14ef840885e33f280d6109d04
1. ALTERAR A BASE PARA MODO RECOVERY FULL;
2. REALIZAR UM BACKUP FULL;
3. REALIZAR UM BACKUP TRANSACIONAL;
4. ADICIONAR A BASE DE VOLTA AO AVAILABILITY GROUP;
<<<<<<< HEAD
5. ADICIONAR A BASE DE VOLTA AO AVAILABLITITY GROUP NA REPLICA SECUND�RIA;
=======
5. ADICIONAR A BASE DE VOLTA AO AVAILABLITITY GROUP NA REPLICA SECUNDÁRIA;
>>>>>>> 8422f51c973655b14ef840885e33f280d6109d04
*/


/*----------------------------------------------------------------------------------------------------------------------------------------------------------- 
<<<<<<< HEAD
QUANDO A ANTIGA REPLICA PRIM�RIA FICAR ONLINE, ELA IR� SUBIR COMO UMA REPLICA SECUND�RIA, POR�M OS DADOS N�O SER�O SINCRONIZADOS AUTOMATICAMENTE.
� NECESS�RIO APLICAR UM RESUME NO ALWAYSON DE CADA BASE DE DADOS 
=======
QUANDO A ANTIGA REPLICA PRIMÁRIA FICAR ONLINE, ELA IRÁ SUBIR COMO UMA REPLICA SECUNDÁRIA, PORÉM OS DADOS NÃO SERÃO SINCRONIZADOS AUTOMATICAMENTE.
É NECESSÁRIO APLICAR UM RESUME NO ALWAYSON DE CADA BASE DE DADOS 
>>>>>>> 8422f51c973655b14ef840885e33f280d6109d04
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

