/* RESULTADO OUTPUT 

dd hh:mm:ss:mss		- Coluna que informa há quanto tempo a query está em execução (para sessões ativas) ou há quanto tempo a última instrução foi executada pela sessão (para sessões inativas - sleeping)
session_id			- Número da sessão que está executando a query (SPID)
sql_text			- XML que contém um trecho da query que está em execução (ou toda a query, se for apenas um statement)
login_name			- Nome do DOMINIO\USUARIO que está executando essa query
wait_info			- Caso a sessão esteja com algum evento de wait, informa há quantos milissegundos esse evento está ocorrendo e qual o tipo de evento (Ex: LCK_M_S, CXPACKET, OLEDB, etc)
CPU					- Medição da quantidade de ciclos de CPU utilizados pela sessão (um número muito alto significa que essa sessão já usou muito CPU do servidor, mas não quer dizer que está utilizando atualmente)
tempdb_allocations	- Quantidade de páginas da TempDB (8 KB cada página) que já foram alocadas para por essa sessão através de tabelas temporárias, spools, LOBs, etc).
					  Um número muito alto aqui, significa que essa sessão tem muitas páginas alocadas, mas não quer dizer que ela é a causadora dos eventos de Autogrow da TempDB.
tempdb_current		- Quantidade de páginas da TempDB que estão sendo alocadas atualmente por essa sessão. Essa conta se resume em quantidade de páginas alocadas - quantidade de páginas desalocadas da TempDB.
					  Um número muito alto aqui, significa que ela é uma possível causadora de eventos de Autogrow na TempDB.
blocking_session_id	- Exibe o número da sessão que está bloqueando a sessão analisada (gerando um evento de wait LCK nessa sessão)
reads				- Quantidade de páginas lógicas de 8 KB lidas da memória do servidor (leitura rápida)
writes				- Quantidade de páginas físicas de 8 KB escritas no disco do servidor
physical_reads		- Quantidade de páginas físicas de 8 KB lidas no disco do servidor (leitura lenta)
used_memory			- Quantidade de páginas de 8 KB utilizadas da memória do servidor pela combinação da procedure cache memory e workspace memory grant.
status				- Define a situação da execução atual da query, que pode ser um dos valores abaixo:
						- Running: Sessão está ativa, executando um ou mais batches. Quer dizer que a sessão está conectada no banco de dados, já enviou os comandos para o servidor e está aguardando o processamento por parte do SQL Server.
						- Suspended: Sessão não está ativa, pois está aguardando algum recurso do servidor (I/O, Rede, etc). Quando esse recurso for liberado, a sessão se tornará ativa novamente e retornará o processamento.
						- Runnable: Sessão já foi atribuída para um worker thread do processador, mas não está conseguindo enviar para o CPU executar. Caso esteja ocorrendo esse evento com muita frequência e por muito tempo no seu ambiente, pode significar que você precisa de aumentar o processador do seu servidor ou diminuir o paralelismo das queries em execução (MAXDOP), que podem estar ocupando todos os núcleos.
						- Pending: Sessão está pronta e aguardando um worker thread do processador pegá-la para executar. É importante ressaltar que isso não significa que você precise aumentar o parâmetro "Max. Worker threads", talvez você precise checar o que as outras threads estão fazendo e porque elas não estão executando.
						- Background: A solicitação está rodando em plano de fundo, geralmente utilizado pelo Resource Monitor ou Deadlock Monitor.
						- Sleeping: Sessão está aberta e conectada no banco, mas não tem nenhuma requisição para processar.
open_tran_count		- Coluna extraída da descontinuada view sysprocesses, que permite visualizar quantas transações abertas ativas a sessão está utilizando e quão profundo é o nível de aninhamento dessas transações.
percent_complete	- Exibe quantos % foi concluído de queries longas (ALTER INDEX REORGANIZE, AUTO_SHRINK option with ALTER DATABASE, BACKUP DATABASE, DBCC CHECKDB, DBCC CHECKFILEGROUP, DBCC CHECKTABLE, DBCC INDEXDEFRAG, DBCC SHRINKDATABASE, DBCC SHRINKFILE, RECOVERY, RESTORE DATABASE, ROLLBACK, TDE ENCRYPTION)
host_name			- Nome da máquina física de onde está vindo a conexão
database_name		- Nome do database atual da conexão, onde estão sendo enviadas as queries
program_name		- Nome do software utilizado durante a conexão (Ex: Microsoft SQL Server Management Studio - Query)
start_time			- Mostra a data de quando a query começou a ser executada
login_time			- Mostra a data que a sessão fez login na instância
request_id			- Número da requisição atual da sessão. Essa coluna não tem uma interpretação muito clara sobre a sua utilidade. Quando o status da sessão for "sleeping", o valor do request_id será geralmente NULL, e caso contrário, será 0 (zero). Caso você encontre um valor maior que 0 (zero) na coluna request_id, significa que essa sessão está executando mais de um batch simultaneamente utilizando o MARS (Multiple Active Result Sets)
collection_time		- Mostra a data da coleta dos dados (data de execução da sp_WhoIsActive)

*/

EXEC master.dbo.sp_WhoIsActive	
	@get_outer_command = 1 -- Add a coluna SQL_COMMAND que retorna todo a query da execução
,	@get_plans = 1 -- Add a coluna QUERY_PLAN
,	@get_transaction_info = 1 -- Add coluna com TRAN_LOG_WRITES com volume de dados escrito no LOG de cada sessão
,	@get_task_info = 2 -- Add as Colunas PHYSICIAL_IO, CONTEXT-SWITCHES para analise de performance
,	@get_locks = 1 -- Add coluna LOCKS solicitado pela sessão
,	@get_avg_time = 1 -- Add coluna [dd hh:mm:ss.mss (avg)] que mostra o tempo médio no trecho atual (Depende do histórico de plano de execução).
,	@find_block_leaders = 1 -- Add coluna BLOCKED_SESSION_COUNT que informa quantas sessões estão dependendo da liberação dessa sessão
,	@show_sleeping_spids = 1 -- Retorna Sessões Sleeping
--,	@delta_interval = 10 -- Realiza 2 consultas no intervalo de 10s para analise de recursos (Add colunas _DELTA)

/****************************** OPÇÕES DE OUTPUT *************************************/
--,	@output_column_list = '[session_id], [dd hh:mm:ss:mss], [start_time], [host_name], [login_name], [database_name], [status], [wait_info] , [CPU], [reads], [writes], [physical_io], [physical_reads]' -- Define saida e colunas
--,	@sort_order = ''

/****************************** OPÇÕES DE FILTRO *************************************/
--,	@filter = '50' -- Permite utilizar %like%
--,	@filter_type = 'session' -- Opções: [session , program , database , login , host]
--,	@not_filter
--,	@not_filter_type