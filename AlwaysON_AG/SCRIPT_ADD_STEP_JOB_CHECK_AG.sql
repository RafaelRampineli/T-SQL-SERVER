use master
go
 
DECLARE @jobname NVARCHAR(MAX)

-- NÃO FAZ NADA CASO NÃO EXISTA AG CONFIGURADO
IF SERVERPROPERTY ('IsHadrEnabled') = 1
BEGIN
    DECLARE @jobid UNIQUEIDENTIFIER = (SELECT sj.job_id FROM msdb.dbo.sysjobs sj WHERE sj.name = @jobname)
 
    IF NOT EXISTS(	SELECT * 
					FROM msdb.dbo.sysjobsteps 
					WHERE job_id = @jobid 
					AND step_name = 'Check If AG Primary' 
	)
    BEGIN
        -- Add new first step: on success go to next step, on failure quit reporting success
        EXEC msdb.dbo.sp_add_jobstep 
          @job_id = @jobid
        , @step_id = 1
        , @cmdexec_success_code = 0
        , @step_name = 'Check If AG Primary'
        , @on_success_action = 3  -- On success, go to Next Step
        , @on_success_step_id = 2
        , @on_fail_action = 1     -- On failure, Quit with Success  
        , @on_fail_step_id = 0
        , @retry_attempts = 0
        , @retry_interval = 0
        , @os_run_priority = 0
        , @subsystem = N'TSQL'
        , @command=N'IF (SELECT ars.role_desc
        FROM sys.dm_hadr_availability_replica_states ars
        JOIN sys.availability_groups ag ON ars.group_id = ag.group_id AND ars.is_local = 1) <> ''Primary''
    BEGIN
       -- Secondary node, throw an error
       raiserror (''Not the AG primary'', 2, 1)
    END'
        , @database_name=N'master'
        , @flags=0
    END
END
GO


--DECLARE @dbname nvarchar(128) = 'SIG'

---- SE A BASE PRINCIPAL NÃO FOR A RÉPLICA PRIMÁRIA DÁ ERRO NO JOB E CANCELA AS EXECUÇÕES 
--If sys.fn_hadr_is_primary_replica (@dbname) <> 1   
--BEGIN 
--   -- Secondary node, throw an error
--    raiserror ('Not the AG primary', 2, 1)
--END 
