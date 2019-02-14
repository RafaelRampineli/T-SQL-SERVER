-- CONTROLAR AS QUERYS MAIS DEMORADAS DO BANCO DE DADOS

-- TABELA PARA ARMAZENAR AS TRACES

CREATE TABLE dbo.TabTrace
(	  Id INT IDENTITY(1,1) PRIMARY KEY NOT NULL	
	, TextData VARCHAR(MAX) NULL
	, NTUserName VARCHAR(128) NULL
	, HostName VARCHAR(128) NULL
	, ApplicationName VARCHAR(128) NULL
    , LoginName VARCHAR(128) NULL
	, SPID INT NULL
	, Duration NUMERIC(15, 2) NULL
	, StartTime DATETIME NULL
	, EndTime DATETIME NULL
	, Reads INT
	, Writes INT
	, CPU INT
	, ServerName VARCHAR(128) NULL
	, DataBaseName VARCHAR(128)
	, RowCounts INT
	, SessionLoginName VARCHAR(128)
)
-- Para realizar as querys de busca pela data que a query rodou.    
CREATE NONCLUSTERED INDEX IX_TabTrace_Id_Login_Duration_Start_End on TabTrace(Id,LoginName,Duration,StartTime,EndTime) WITH (FILLFACTOR=95)
CREATE NONCLUSTERED INDEX IX_TabTrace_Duration on TabTrace(Duration) WITH (FILLFACTOR=95)


-- PROCEDURE QUE FICARÁ MONITORANDO AS TRACES.

CREATE PROCEDURE [dbo].[proc_MonitoraTrace]
AS
BEGIN
    DECLARE	  @rc INT
			, @TraceID INT
			, @maxfilesize BIGINT
			, @on BIT
			, @intfilter INT
			, @bigintfilter BIGINT
            
    SELECT @on = 1, 
		   @maxfilesize = 500

    -- Criação do trace
EXEC  sp_trace_create @TraceID OUTPUT, 0, N'C:\Trace\Querys_Demoradas', @maxfilesize, NULL
    --EXEC @rc = sp_trace_create @TraceID OUTPUT, 0, N'C:\Trace\Querys_Demoradas', @maxfilesize, NULL
    
    IF (@rc != 0) GOTO ERROR
    
    EXEC sp_trace_setevent @TraceID, 10, 1, @on
    EXEC sp_trace_setevent @TraceID, 10, 6, @on
    EXEC sp_trace_setevent @TraceID, 10, 8, @on
    EXEC sp_trace_setevent @TraceID, 10, 10, @on
    EXEC sp_trace_setevent @TraceID, 10, 11, @on
    EXEC sp_trace_setevent @TraceID, 10, 12, @on
    EXEC sp_trace_setevent @TraceID, 10, 13, @on
    EXEC sp_trace_setevent @TraceID, 10, 14, @on
    EXEC sp_trace_setevent @TraceID, 10, 15, @on
    EXEC sp_trace_setevent @TraceID, 10, 16, @on
    EXEC sp_trace_setevent @TraceID, 10, 17, @on
    EXEC sp_trace_setevent @TraceID, 10, 18, @on
    EXEC sp_trace_setevent @TraceID, 10, 26, @on
    EXEC sp_trace_setevent @TraceID, 10, 35, @on
    EXEC sp_trace_setevent @TraceID, 10, 40, @on
    EXEC sp_trace_setevent @TraceID, 10, 48, @on
    EXEC sp_trace_setevent @TraceID, 10, 64, @on
    EXEC sp_trace_setevent @TraceID, 12, 1,  @on
    EXEC sp_trace_setevent @TraceID, 12, 6,  @on
    EXEC sp_trace_setevent @TraceID, 12, 8,  @on
    EXEC sp_trace_setevent @TraceID, 12, 10, @on
    EXEC sp_trace_setevent @TraceID, 12, 11, @on
    EXEC sp_trace_setevent @TraceID, 12, 12, @on
    EXEC sp_trace_setevent @TraceID, 12, 13, @on
    EXEC sp_trace_setevent @TraceID, 12, 14, @on
    EXEC sp_trace_setevent @TraceID, 12, 15, @on
    EXEC sp_trace_setevent @TraceID, 12, 16, @on
    EXEC sp_trace_setevent @TraceID, 12, 17, @on
    EXEC sp_trace_setevent @TraceID, 12, 18, @on
    EXEC sp_trace_setevent @TraceID, 12, 26, @on
    EXEC sp_trace_setevent @TraceID, 12, 35, @on
    EXEC sp_trace_setevent @TraceID, 12, 40, @on
    EXEC sp_trace_setevent @TraceID, 12, 48, @on
    EXEC sp_trace_setevent @TraceID, 12, 64, @on

    SET @bigintfilter = 1000000 -- 3 segundos  ( Irá pegar Querys que demoram acima de 3 segundos para executar ).

    EXEC sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

    -- Set the trace status to start
    EXEC sp_trace_setstatus @TraceID, 1

    GOTO finish
    error:

    SELECT ErrorCode=@rc
    finish:
END


-- EXECUTAR A PROCEDURE E CRIAR O TRACE

EXEC dbo.proc_stpCreate_Trace

-- CONSULTAR O TRACE

DECLARE @TraceID int

SELECT @TraceID = traceid
FROM :: fn_trace_getinfo(default)
where cast(value as varchar(50)) = 'C:\Trace\Querys_Demoradas.trc'
SELECT @TraceID
-- PARAR O TRACE

EXEC sp_trace_setstatus @TraceID, 0
EXEC sp_trace_setstatus @TraceID, 2

-- APAGAR O ARQUIVO DO TRACE

EXEC xp_cmdshell 'del C:\Trace\Querys_Demoradas.trc /Q'

-- CONSULTAR OS RESGISTROS QUE ESTÃO NO TRACE

Select Textdata, NTUserName, HostName, ApplicationName, LoginName, SPID, cast(Duration /1000/1000.00 as numeric(15,2)) Duration, Starttime,
    EndTime, Reads,writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName
FROM :: fn_trace_gettable('C:\Trace\Querys_Demoradas.trc', default)
where Duration is not null
order by Starttime
