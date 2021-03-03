-- SCRIPT FAILOVER MANUAL PLANEJADO

DECLARE @AVAILABILITY_GROUP VARCHAR(200) = 'WorkGroup_AG',
		@FAILOVER_REPLICA VARCHAR(200) = 'WIN2019STD', -- NOME DA REPLICA QUE IR� SE TORNAR PRIM�RIA
		@PRIMARY_ATUAL_REPLICA VARCHAR(200) = 'WIN2019STD02'

/* TORNANDO O MODO DE SINCRONIZA��O SINCRONA */
SELECT	'STEP 1: EXECUTAR O COMANDO NA REPLICA PRIM�RIA:', 
		'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' MODIFY REPLICA ON ' + '''' + replica_server_name + '''' + ' WITH ( AVAILABILITY_MODE = SYNCHRONOUS_COMMIT );'
FROM sys.availability_replicas
WHERE replica_server_name IN (@PRIMARY_ATUAL_REPLICA, @FAILOVER_REPLICA)


/* AP�S EXECUTAR O CMD DO RESULTADO ACIMA, VERIFICAR SE A R�PLICA QUE IR� SE TORNAR PRIM�RIA, EST� PRONTA PARA O FAILOVER E SE O STATUS EST� SYNCHRONIZED */
SELECT DISTINCT database_name, drs.synchronization_state_desc, a.is_failover_ready, b.replica_server_name
FROM sys.dm_hadr_database_replica_cluster_states a
inner join sys.availability_replicas b on a.replica_id = b.replica_id
inner join sys.dm_hadr_database_replica_states drs on drs.replica_id = a.replica_id
WHERE b.replica_server_name = @FAILOVER_REPLICA


select * from sys.dm_hadr_database_replica_states
/* EXECUTAR O FAIOLVER CONECTAD NA REPLICA SECUND�RIA QUE IR� SE TORNAR PRIM�RIA */
SELECT	'STEP 2: EXECUTAR O COMANDO NA REPLICA SECUND�RIA:', 
		'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' FAILOVER;'

/* RETORNAR PARA O MODO DE SINCRONIZA��O ASSINCRONA */
SELECT	'STEP 3: EXECUTAR O COMANDO NA NOVA REPLICA PRIM�RIA:', 
		'ALTER AVAILABILITY GROUP ' + @AVAILABILITY_GROUP + ' MODIFY REPLICA ON ' + '''' + replica_server_name + '''' + ' WITH ( AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT );'
FROM sys.availability_replicas
WHERE replica_server_name IN (@PRIMARY_ATUAL_REPLICA, @FAILOVER_REPLICA)


