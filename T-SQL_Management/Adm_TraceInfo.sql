--Informacoes de Traces executando
SELECT * FROM sys.traces
SELECT * FROM ::fn_trace_getinfo(default) WHERE traceid IN (5,6,7);

--EXEC sp_trace_setstatus @traceid =  7 , @status = 0

--EXEC sp_trace_setstatus @traceid =  5 , @status = 1
--EXEC sp_trace_setstatus @traceid =  6 , @status = 1
--EXEC sp_trace_setstatus @traceid =  7 , @status = 1