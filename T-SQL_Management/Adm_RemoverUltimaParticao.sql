BEGIN

	
	PRINT 'EXISTE UM "RETURN" DE SEGURANÇA NO CÓDIGO DESTA PROCEDURE PARA EVITAR EXECUÇÃO EM AMBIENTE DE PRODUÇÃO'
	PRINT 'SE QUISER UTILIZAR ESTA PROCEDURE EM AMBIENTE DE DESENVOLVIMENTO, FAVOR RETIRAR O RETURN'
	RETURN;

	--Sufixo que será adicionado as tabelas para indicar que estas representam uma tabela temporária para movimentaçao de dados (staging)
	DECLARE @sufixoStaging VARCHAR (50) = '_tempStaging'
	DECLARE @databaseAtual VARCHAR(200) = DB_NAME()
	DECLARE @schema VARCHAR(200) = 'dbo'
	
	DECLARE @comandoSQL NVARCHAR(MAX)	
	DECLARE @parmDefinition NVARCHAR(MAX)
	DECLARE @varExisteTabela BIT = 0
	DECLARE @varTabelaStaging VARCHAR(250) = ''

	DECLARE @nomeFileGroup VARCHAR(MAX)
	DECLARE @LimiteInferior DATETIME
	DECLARE @LimiteSuperior DATETIME
	DECLARE @varQtdParticoes INT
	DECLARE @varQtdRegistros INT = NULL

	IF OBJECT_ID('tempdb..#indicesTabela') IS NOT NULL DROP TABLE #indicesTabela
	CREATE TABLE #indicesTabela (nomeIndice VARCHAR(250), 
								dataCompression VARCHAR(50),
								tipoIndice		VARCHAR(50))

	DECLARE @nomeIndice VARCHAR(250)
	DECLARE @dataCompression VARCHAR(50)
	DECLARE @tipoIndice		VARCHAR(50)


	DECLARE @retry TINYINT = 5
	DECLARE @varErro VARCHAR(MAX)

	DECLARE @nomeTabela VARCHAR(150), @partitionScheme VARCHAR(150), @partitionFunction VARCHAR(150)

	
	--Sufixo para staging não pode em hipótese nenhuma ser vazio. 
	IF @sufixoStaging = ''
	BEGIN		
		PRINT 'O sufixo para tabelas de staging não pode ser vazio'
		RETURN
	END

	--Buscar na database alvo informacoes para avaliarmos se já é hora de arquivar uma particao
	SET @comandoSQL =
		N'SELECT	TOP 1
				@limiteInferiorOUT = CAST(value AS DATETIME),
				@limiteSuperiorOUT = FIRST_VALUE(CAST(value AS DATETIME)) OVER (ORDER BY CAST(value AS DATETIME) DESC),
				@filegroupOUT = LEAD(fg.name) OVER (ORDER BY CAST(value AS DATETIME)),
				@qtdParticoesOUT = COUNT(*) OVER ()
		FROM sys.partition_range_values pr
		INNER JOIN sys.partition_functions pf ON pf.function_id = pr.function_id
		JOIN sys.partition_schemes ps ON ps.function_id = pf.function_id
		JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = pr.boundary_id
		JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
		ORDER BY CAST(value AS DATETIME)'

	SET @parmDefinition = N'@qtdParticoesOUT smallint OUTPUT, 
							 @limiteInferiorOUT datetime OUTPUT,  
							 @limiteSuperiorOUT datetime OUTPUT, 
							 @filegroupOUT VARCHAR(150) OUTPUT'

	EXEC sp_executesql	@statement = @comandoSQL, 
						@params = @parmDefinition, 
						@qtdParticoesOUT= @varQtdParticoes OUTPUT,
						@limiteInferiorOUT = @LimiteInferior OUTPUT,
						@limiteSuperiorOUT = @LimiteSuperior OUTPUT,
						@filegroupOUT = @nomeFileGroup OUTPUT
	


	--Se a quantidade de partiçoes na database alvo for maior do que precisamos manter, entao é hora de arquivarmos uma partiçao
	IF @LimiteInferior IS NOT NULL
	BEGIN
	

/****************************************************************************************************************************************************
												REMOVER REGISTROS DA PARTIÇÃO A SER REMOVIDA
*****************************************************************************************************************************************************/	
		
		PRINT ''
		PRINT '==========================================================================================='
		PRINT '					INICIANDO REMOÇÃO DA PARTIÇÃO: '+@nomeFileGroup
		PRINT '==========================================================================================='


		IF OBJECT_ID('tempdb..#TabelasParticionadas') IS NOT NULL DROP TABLE #TabelasParticionadas
		CREATE TABLE #TabelasParticionadas (nomeTabela VARCHAR(150), partition_scheme VARCHAR(150), partition_function VARCHAR(150) )

		
		--Buscar todas as tabelas particionadas pela partition function solicitada que irao ser copiadas para o arquivo
		SET @comandoSQL =
				N'	SELECT
							OBJECT_NAME(i.object_id) AS ObjectName,
							ps.name partition_scheme,
							f.name partition_function
					FROM sys.partitions p
					JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
					JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
					JOIN sys.partition_functions f ON f.function_id = ps.function_id
					LEFT JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
					JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
					JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
					WHERE fg.name = '''+@nomeFileGroup+'''
						AND rows > 0
						AND OBJECT_NAME(i.object_id) NOT LIKE ''%'+@sufixoStaging+''' 
					'		

		INSERT INTO #TabelasParticionadas
		EXEC sp_executeSQL @statement = @comandoSQL	
		

		DECLARE curTabelasPart CURSOR LOCAL STATIC FORWARD_ONLY
		FOR SELECT nomeTabela, partition_scheme, partition_function FROM #TabelasParticionadas FOR READ ONLY		

		OPEN curTabelasPart

		FETCH NEXT FROM curTabelasPart INTO @nomeTabela, @partitionScheme, @partitionFunction

		WHILE @@FETCH_STATUS = 0 
		BEGIN
  
			PRINT ''			
			PRINT '/*** LIMPANDO DADOS DE '+@nomeFileGroup+' NA TABELA: ' + @nomeTabela + ' ***/'
			
			SET @varTabelaStaging = @nomeTabela+@sufixoStaging;

			BEGIN TRANSACTION 

			---------------------------------     CRIAR TABELA STAGING     --------------------------------------------
			
			SET @varExisteTabela = 0
			SET @comandoSQL = 'SELECT @varExisteTabela = CAST(1 AS BIT) FROM sys.tables WHERE name = '''+@varTabelaStaging+''''			
			PRINT @comandoSQL
			EXEC sp_executeSQL @comandoSQL, N'@varExisteTabela BIT OUTPUT', @varExisteTabela OUTPUT;			

			IF @varExisteTabela = 1 AND @nomeTabela != @varTabelaStaging
				BEGIN
					SET @comandoSQL = 'DROP TABLE '+@varTabelaStaging
					PRINT @comandoSQL
					EXEC sp_executeSQL @comandoSQL, N'@varExisteTabela BIT OUTPUT', @varExisteTabela OUTPUT;			
				END
			
			SET @comandoSQL = NULL;

			--Criando tabela de staging para realizar o partition switch			
			EXEC dbo.proc_ScriptTable
				@DBName                = @databaseAtual
			  , @schema                = 'dbo'
			  , @TableName             = @nomeTabela
			  , @NewTableSchema        = 'dbo'
			  , @NewTableName          = @varTabelaStaging
			  , @script                = @comandoSQL OUTPUT
			
			EXEC sp_executesql @statement = @comandoSQL

			---------------------------------------		AJUSTE DE ÍNDICES	-------------------------------------------------

			TRUNCATE TABLE #indicesTabela

			--Buscar todas as tabelas particionadas pela partition function solicitada que irao ser copiadas para o arquivo
			SET @comandoSQL =
					N'WITH indices_tabela_principal AS 
							(SELECT i.name , p.data_compression_desc, i.type_desc,
									STRING_AGG(CASE WHEN cc.is_included_column = 0 THEN c.name END,'', '') WITHIN GROUP (ORDER BY cc.key_ordinal, c.name) colunas_principais,
									STRING_AGG(CASE WHEN cc.is_included_column = 1 THEN c.name END,'', '') WITHIN GROUP (ORDER BY cc.key_ordinal, c.name) colunas_incluidas
							FROM sys.partitions p
							JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
							JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
							JOIN sys.tables t ON p.object_id = t.object_id
							LEFT JOIN sys.index_columns cc ON i.index_id = cc.index_id AND cc.object_id = i.object_id
							LEFT JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id 
							WHERE p.partition_number = $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@limiteInferior,120)+''')'+'
								AND OBJECT_NAME(i.object_id) = '''+@nomeTabela+'''
							GROUP BY i.name, p.data_compression_desc, i.type_desc),
						indices_tabela_staging AS 
							(SELECT i.name , p.data_compression_desc, i.type_Desc,
									STRING_AGG(CASE WHEN cc.is_included_column = 0 THEN c.name END,'', '') WITHIN GROUP (ORDER BY cc.key_ordinal, c.name) colunas_principais,
									STRING_AGG(CASE WHEN cc.is_included_column = 1 THEN c.name END,'', '') WITHIN GROUP (ORDER BY cc.key_ordinal, c.name) colunas_incluidas
							FROM sys.partitions p
							JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
							JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
							JOIN sys.tables t ON p.object_id = t.object_id
							LEFT JOIN sys.index_columns cc ON i.index_id = cc.index_id AND cc.object_id = i.object_id
							LEFT JOIN sys.columns c ON cc.object_id = c.object_id AND cc.column_id = c.column_id 
							WHERE p.partition_number = $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@limiteInferior,120)+''')'+'
								AND OBJECT_NAME(i.object_id) = '''+@varTabelaStaging+'''
							GROUP BY i.name, p.data_compression_desc, i.type_desc)
						SELECT its.name, MAX(itp.data_compression_desc) data_compression_desc, its.type_desc
						FROM indices_tabela_staging its
						INNER JOIN indices_tabela_principal itp ON its.colunas_principais = itp.colunas_principais
																	AND COALESCE(its.colunas_incluidas,'''') = COALESCE(itp.colunas_incluidas,'''')
																	AND itp.type_desc = its.type_desc
						GROUP BY its.name, its.type_desc'
				



			INSERT INTO #indicesTabela
			EXEC sp_executeSQL @statement = @comandoSQL

			DECLARE curIndices CURSOR LOCAL STATIC FORWARD_ONLY
			FOR SELECT nomeIndice, dataCompression, tipoIndice
			FROM #indicesTabela FOR READ ONLY

			OPEN curIndices

			FETCH NEXT FROM curIndices INTO @nomeIndice, @dataCompression, @tipoIndice;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				IF @tipoIndice IN ('CLUSTERED','NONCLUSTERED')
				BEGIN
					SET @comandoSQL = 'ALTER INDEX '+@nomeIndice+' ON '+@varTabelaStaging + ' REBUILD PARTITION = $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@LimiteInferior,120)+''')'
						+' WITH (SORT_IN_TEMPDB=ON, DATA_COMPRESSION='+@dataCompression+')'
					PRINT @comandoSQL
					EXEC sp_executeSQL @statement = @comandoSQL
				END

				IF @tipoIndice = 'HEAP'
				BEGIN
					SET @comandoSQL = 'ALTER TABLE '+@varTabelaStaging+' REBUILD PARTITION = $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@LimiteInferior,120)+''')'
						+' WITH (DATA_COMPRESSION='+@dataCompression+')'
					PRINT @comandoSQL
					EXEC sp_executeSQL @statement = @comandoSQL
				END

				FETCH NEXT FROM curIndices INTO @nomeIndice, @dataCompression, @tipoIndice;
			END

			CLOSE curIndices
			DEALLOCATE curIndices

			---------------------------------------		PARTITION SWITCH	-------------------------------------------------


			--Remover os dados da tabela através do partition switch
			IF @nomeTabela != @varTabelaStaging
			BEGIN
				--Realizar o partition switch na database alvo da tabela principal para a tabela stage
				SET @comandoSQL = 'ALTER TABLE '+@nomeTabela+' SWITCH PARTITION $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@limiteInferior,120)+''') TO '
				+@varTabelaStaging+' PARTITION $PARTITION.'+@partitionFunction+'('''+CONVERT(VARCHAR(40),@limiteInferior,120)+''')' 
				PRINT @comandoSQL
				EXEC sp_executeSQL @statement = @comandoSQL				

			
				--Truncar dados que acabaram de ser arquivados na database alvo
				SET @comandoSQL = 'TRUNCATE TABLE '+@varTabelaStaging
				PRINT @comandoSQL
				EXEC sp_executesql @statement = @comandoSQL

			
				--Realizar drop da tabela de staging
				SET @comandoSQL = 'DROP TABLE '+@varTabelaStaging
				PRINT @comandoSQL
				EXEC sp_executesql @statement = @comandoSQL
			END

			COMMIT TRANSACTION


			FETCH NEXT FROM curTabelasPart INTO @nomeTabela, @partitionScheme, @partitionFunction

		END

		CLOSE curTabelasPart
		DEALLOCATE curTabelasPart


		PRINT 'TODAS AS TABELAS DA PARTIÇÃO '+@nomeFileGroup+' ESTÃO VAZIAS...'

	END


/*********************************************************************************************************************************************
									AJUSTAR FILEGROUPS, PARTITION SCHEMES E PARTITION FUNCTIONS NA DATABASE ALVO
**********************************************************************************************************************************************/
	PRINT ''	
	PRINT 'INICIANDO AJUSTES FINAIS NA DATABASE...'
		
	--------------------------------------------     AJUSTAR PARTITION FUNCTION E SCHEME    ----------------------------------------------
	IF OBJECT_ID('tempdb..#funcoesParticionamento') IS NOT NULL DROP TABLE #funcoesParticionamento
	CREATE TABLE #funcoesParticionamento (partition_function VARCHAR(150) )

		
	--Buscar todas as tabelas particionadas pela partition function solicitada que irao ser copiadas para o arquivo
	SET @comandoSQL =
					N'	SELECT DISTINCT
								f.name partition_function
						FROM sys.partitions p
						JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
						JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
						JOIN sys.partition_functions f ON f.function_id = ps.function_id
						LEFT JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
						JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
						JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
						WHERE fg.name = '''+@nomeFileGroup+'''
				'		

	INSERT INTO #funcoesParticionamento
	EXEC sp_executeSQL @statement = @comandoSQL	
		

	DECLARE curFuncoesPart CURSOR LOCAL STATIC FORWARD_ONLY
	FOR SELECT partition_function FROM #funcoesParticionamento FOR READ ONLY		

	OPEN curFuncoesPart

	FETCH NEXT FROM curFuncoesPart INTO @partitionFunction

	WHILE @@FETCH_STATUS = 0 
	BEGIN


		SET @retry = 1
		WHILE @retry <= 50
		BEGIN
			BEGIN TRY
				-- Juntar a partiçao que foi arquivada na database alvo
				SET @comandoSQL = 'SET DEADLOCK_PRIORITY HIGH;  ALTER PARTITION FUNCTION ' + @partitionFunction + '() MERGE RANGE ('''+ CONVERT(VARCHAR(40),@LimiteInferior,120)+''')'
				PRINT @comandoSQL
				PRINT 'Tentativa: ' + CONVERT(VARCHAR,@retry)
				EXEC sp_executesql @statement = @comandoSQL
				BREAK
			END TRY
			BEGIN CATCH
				IF (ERROR_NUMBER() = 1205 OR ERROR_NUMBER() = 1222)
				BEGIN
					SET @retry = @retry + 1
					IF @retry > 50
						RAISERROR('Erro ao Arquivar partição. Número de Tentativas excedido',16,1);
					WAITFOR DELAY '00:00:02' -- Esperar 2 segundos
					CONTINUE
				END
				ELSE
				BEGIN
					SET @varErro = 'Erro diferente de deadlock encontrado: ' + ERROR_MESSAGE()
					RAISERROR(@varErro,16,1);
					BREAK;
				END
			END CATCH
		END
			
		FETCH NEXT FROM curFuncoesPart INTO @partitionFunction
	END

	PRINT ''
	PRINT 'FUNÇÕES DE PARTICIONAMENTO FORAM AJUSTADAS...'

	----------------------------------------------------     REMOVER FILEGROUP     --------------------------------------------------------
		
	IF OBJECT_ID('tempdb..#TabArquivoRemocao') IS NOT NULL DROP TABLE #TabArquivoRemocao
	CREATE TABLE #TabArquivoRemocao (NomeArquivo VARCHAR(150))

	DECLARE @nomeArquivo VARCHAR(150)
		
	SET @comandoSQL = 'SELECT df.name FROM sys.database_files df INNER JOIN sys.filegroups fg ON df.data_space_id = fg.data_space_id '
			+'WHERE fg.name = '''+@nomeFileGroup+''''
		
	INSERT INTO #TabArquivoRemocao
	EXEC sp_executesql @statement = @comandoSQL
		
	DECLARE cur_files CURSOR LOCAL STATIC FORWARD_ONLY FOR
	SELECT nomeArquivo FROM #TabArquivoRemocao

	OPEN cur_files
	FETCH NEXT FROM cur_files INTO @nomeArquivo


	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @comandoSQL = 'ALTER DATABASE '+DB_NAME()+' REMOVE FILE '+@nomeArquivo
		PRINT @comandoSQL
		EXEC sp_executeSQL @statement = @comandoSQL

		FETCH NEXT FROM cur_files INTO @nomeArquivo

	END

	CLOSE cur_files
	DEALLOCATE cur_files

	SET @comandoSQL = 'ALTER DATABASE '+DB_NAME()+' REMOVE FILEGROUP '+@nomeFileGroup
	PRINT @comandoSQL
	EXEC sp_executeSQL @statement = @comandoSQL
	
  
  	PRINT ''
	PRINT	'==========================================================================================='
	PRINT	'							REMOÇÃO DE PARTIÇÃO CONCLUÍDO COM SUCESSO'
	PRINT	'==========================================================================================='      
  
  
END