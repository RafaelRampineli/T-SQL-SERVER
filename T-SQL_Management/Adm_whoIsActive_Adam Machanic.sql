/* RESULTADO OUTPUT 

dd hh:mm:ss:mss		- Coluna que informa h� quanto tempo a query est� em execu��o (para sess�es ativas) ou h� quanto tempo a �ltima instru��o foi executada pela sess�o (para sess�es inativas - sleeping)
session_id			- N�mero da sess�o que est� executando a query (SPID)
sql_text			- XML que cont�m um trecho da query que est� em execu��o (ou toda a query, se for apenas um statement)
login_name			- Nome do DOMINIO\USUARIO que est� executando essa query
wait_info			- Caso a sess�o esteja com algum evento de wait, informa h� quantos milissegundos esse evento est� ocorrendo e qual o tipo de evento (Ex: LCK_M_S, CXPACKET, OLEDB, etc)
CPU					- Medi��o da quantidade de ciclos de CPU utilizados pela sess�o (um n�mero muito alto significa que essa sess�o j� usou muito CPU do servidor, mas n�o quer dizer que est� utilizando atualmente)
tempdb_allocations	- Quantidade de p�ginas da TempDB (8 KB cada p�gina) que j� foram alocadas para por essa sess�o atrav�s de tabelas tempor�rias, spools, LOBs, etc).
					  Um n�mero muito alto aqui, significa que essa sess�o tem muitas p�ginas alocadas, mas n�o quer dizer que ela � a causadora dos eventos de Autogrow da TempDB.
tempdb_current		- Quantidade de p�ginas da TempDB que est�o sendo alocadas atualmente por essa sess�o. Essa conta se resume em quantidade de p�ginas alocadas - quantidade de p�ginas desalocadas da TempDB.
					  Um n�mero muito alto aqui, significa que ela � uma poss�vel causadora de eventos de Autogrow na TempDB.
blocking_session_id	- Exibe o n�mero da sess�o que est� bloqueando a sess�o analisada (gerando um evento de wait LCK nessa sess�o)
reads				- Quantidade de p�ginas l�gicas de 8 KB lidas da mem�ria do servidor (leitura r�pida)
writes				- Quantidade de p�ginas f�sicas de 8 KB escritas no disco do servidor
physical_reads		- Quantidade de p�ginas f�sicas de 8 KB lidas no disco do servidor (leitura lenta)
used_memory			- Quantidade de p�ginas de 8 KB utilizadas da mem�ria do servidor pela combina��o da procedure cache memory e workspace memory grant.
status				- Define a situa��o da execu��o atual da query, que pode ser um dos valores abaixo:
						- Running: Sess�o est� ativa, executando um ou mais batches. Quer dizer que a sess�o est� conectada no banco de dados, j� enviou os comandos para o servidor e est� aguardando o processamento por parte do SQL Server.
						- Suspended: Sess�o n�o est� ativa, pois est� aguardando algum recurso do servidor (I/O, Rede, etc). Quando esse recurso for liberado, a sess�o se tornar� ativa novamente e retornar� o processamento.
						- Runnable: Sess�o j� foi atribu�da para um worker thread do processador, mas n�o est� conseguindo enviar para o CPU executar. Caso esteja ocorrendo esse evento com muita frequ�ncia e por muito tempo no seu ambiente, pode significar que voc� precisa de aumentar o processador do seu servidor ou diminuir o paralelismo das queries em execu��o (MAXDOP), que podem estar ocupando todos os n�cleos.
						- Pending: Sess�o est� pronta e aguardando um worker thread do processador peg�-la para executar. � importante ressaltar que isso n�o significa que voc� precise aumentar o par�metro "Max. Worker threads", talvez voc� precise checar o que as outras threads est�o fazendo e porque elas n�o est�o executando.
						- Background: A solicita��o est� rodando em plano de fundo, geralmente utilizado pelo Resource Monitor ou Deadlock Monitor.
						- Sleeping: Sess�o est� aberta e conectada no banco, mas n�o tem nenhuma requisi��o para processar.
open_tran_count		- Coluna extra�da da descontinuada view sysprocesses, que permite visualizar quantas transa��es abertas ativas a sess�o est� utilizando e qu�o profundo � o n�vel de aninhamento dessas transa��es.
percent_complete	- Exibe quantos % foi conclu�do de queries longas (ALTER INDEX REORGANIZE, AUTO_SHRINK option with ALTER DATABASE, BACKUP DATABASE, DBCC CHECKDB, DBCC CHECKFILEGROUP, DBCC CHECKTABLE, DBCC INDEXDEFRAG, DBCC SHRINKDATABASE, DBCC SHRINKFILE, RECOVERY, RESTORE DATABASE, ROLLBACK, TDE ENCRYPTION)
host_name			- Nome da m�quina f�sica de onde est� vindo a conex�o
database_name		- Nome do database atual da conex�o, onde est�o sendo enviadas as queries
program_name		- Nome do software utilizado durante a conex�o (Ex: Microsoft SQL Server Management Studio - Query)
start_time			- Mostra a data de quando a query come�ou a ser executada
login_time			- Mostra a data que a sess�o fez login na inst�ncia
request_id			- N�mero da requisi��o atual da sess�o. Essa coluna n�o tem uma interpreta��o muito clara sobre a sua utilidade. Quando o status da sess�o for "sleeping", o valor do request_id ser� geralmente NULL, e caso contr�rio, ser� 0 (zero). Caso voc� encontre um valor maior que 0 (zero) na coluna request_id, significa que essa sess�o est� executando mais de um batch simultaneamente utilizando o MARS (Multiple Active Result Sets)
collection_time		- Mostra a data da coleta dos dados (data de execu��o da sp_WhoIsActive)

*/

EXEC master.dbo.sp_WhoIsActive	
	@get_outer_command = 1 -- Add a coluna SQL_COMMAND que retorna todo a query da execu��o
,	@get_plans = 1 -- Add a coluna QUERY_PLAN
,	@get_transaction_info = 1 -- Add coluna com TRAN_LOG_WRITES com volume de dados escrito no LOG de cada sess�o
,	@get_task_info = 2 -- Add as Colunas PHYSICIAL_IO, CONTEXT-SWITCHES para analise de performance
,	@get_locks = 1 -- Add coluna LOCKS solicitado pela sess�o
,	@get_avg_time = 1 -- Add coluna [dd hh:mm:ss.mss (avg)] que mostra o tempo m�dio no trecho atual (Depende do hist�rico de plano de execu��o).
,	@find_block_leaders = 1 -- Add coluna BLOCKED_SESSION_COUNT que informa quantas sess�es est�o dependendo da libera��o dessa sess�o
,	@show_sleeping_spids = 1 -- Retorna Sess�es Sleeping
--,	@delta_interval = 10 -- Realiza 2 consultas no intervalo de 10s para analise de recursos (Add colunas _DELTA)

/****************************** OP��ES DE OUTPUT *************************************/
--,	@output_column_list = '[session_id], [dd hh:mm:ss:mss], [start_time], [host_name], [login_name], [database_name], [status], [wait_info] , [CPU], [reads], [writes], [physical_io], [physical_reads]' -- Define saida e colunas
--,	@sort_order = ''

/****************************** OP��ES DE FILTRO *************************************/
--,	@filter = '50' -- Permite utilizar %like%
--,	@filter_type = 'session' -- Op��es: [session , program , database , login , host]
--,	@not_filter
--,	@not_filter_type