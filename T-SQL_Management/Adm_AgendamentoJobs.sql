--Agendamento das Jobs SQL Server
SELECT sJOB.name AS [Nome Job]
     , CASE sJOB.enabled
          WHEN 1 THEN 'SIM'
          WHEN 0 THEN 'NÃO'
       END AS [Job Ativo]
     , CASE
          WHEN sSCH.schedule_uid IS NULL THEN 'NÃO'
          ELSE 'SIM'
       END AS [Está Agendado]
     , sJSTP.STEP_ID AS [Sequencia Step]
	 , sJSTP.STEP_NAME AS [Nome Step]
     , CASE freq_type
          WHEN 1 THEN 'One Time'
          WHEN 4 THEN 'Daily'
          WHEN 8 THEN 'Weekly'
          WHEN 16 THEN 'Monthly'
          WHEN 32 THEN 'Monthly - Relative to Frequency Interval'
          WHEN 64 THEN 'Start automatically when SQL Server Agent starts'
          WHEN 128 THEN 'Start whenever the CPUs become idle'
       END [Ocorrência]
     , CASE freq_type
          WHEN 4 THEN 'Occurs every ' + CAST(freq_interval AS VARCHAR(3)) + ' day(s)'
          WHEN 8 THEN 'Occurs every ' + CAST(freq_recurrence_factor AS VARCHAR(3)) 
                    + ' week(s) on '
                    + CASE WHEN freq_interval & 1 = 1 THEN 'Sunday' ELSE '' END
                    + CASE WHEN freq_interval & 2 = 2 THEN ', Monday' ELSE '' END
                    + CASE WHEN freq_interval & 4 = 4 THEN ', Tuesday' ELSE '' END
                    + CASE WHEN freq_interval & 8 = 8 THEN ', Wednesday' ELSE '' END
                    + CASE WHEN freq_interval & 16 = 16 THEN ', Thursday' ELSE '' END
                    + CASE WHEN freq_interval & 32 = 32 THEN ', Friday' ELSE '' END
                    + CASE WHEN freq_interval & 64 = 64 THEN ', Saturday' ELSE '' END
          WHEN 16 THEN 'Occurs on Day ' + CAST(freq_interval AS VARCHAR(3)) 
                    + ' of every '
                    + CAST(freq_recurrence_factor AS VARCHAR(3)) + ' month(s)'
          WHEN 32 THEN 'Occurs on '
                    + CASE freq_relative_interval
                         WHEN 1 THEN 'First'
						 WHEN 2 THEN 'Second'
                         WHEN 4 THEN 'Third'
                         WHEN 8 THEN 'Fourth'
                         WHEN 16 THEN 'Last'
                      END
                     + ' ' 
                     + CASE freq_interval
                          WHEN 1 THEN 'Sunday'
                          WHEN 2 THEN 'Monday'
                          WHEN 3 THEN 'Tuesday'
                          WHEN 4 THEN 'Wednesday'
                          WHEN 5 THEN 'Thursday'
                          WHEN 6 THEN 'Friday'
                          WHEN 7 THEN 'Saturday'
                          WHEN 8 THEN 'Day'
                          WHEN 9 THEN 'Weekday'
                          WHEN 10 THEN 'Weekend day'
                       END
                     + ' of every ' + CAST(freq_recurrence_factor AS VARCHAR(3)) 
                     + ' month(s)'
      END AS [Recorrência]
    , CASE freq_subday_type
        WHEN 1 THEN 'Occurs once at ' + STUFF(STUFF(RIGHT('000000' + CAST(active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 2 THEN 'Occurs every ' + CAST(freq_subday_interval AS VARCHAR(3)) + ' Second(s) between ' + STUFF( STUFF(RIGHT('000000' + CAST(active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
                    + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST(active_end_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 4 THEN 'Occurs every ' + CAST(freq_subday_interval AS VARCHAR(3)) + ' Minute(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST(active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
                    + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST(active_end_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        WHEN 8 THEN 'Occurs every ' + CAST(freq_subday_interval AS VARCHAR(3)) + ' Hour(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST(active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
                    + ' & ' + STUFF(STUFF(RIGHT('000000' + CAST(active_end_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
      END AS [Frequência]
FROM msdb.dbo.sysjobs AS sJOB
LEFT JOIN msdb.sys.servers AS sSVR
  ON sJOB.originating_server_id = sSVR.server_id
LEFT JOIN msdb.dbo.syscategories AS sCAT
  ON sJOB.category_id = sCAT.category_id
LEFT JOIN msdb.dbo.sysjobsteps AS sJSTP
  ON sJOB.job_id = sJSTP.job_id
LEFT JOIN msdb.sys.database_principals AS sDBP
  ON sJOB.owner_sid = sDBP.sid
LEFT JOIN msdb.dbo.sysjobschedules AS sJOBSCH
  ON sJOB.job_id = sJOBSCH.job_id
LEFT JOIN msdb.dbo.sysschedules AS sSCH
  ON sJOBSCH.schedule_id = sSCH.schedule_id
ORDER BY [Nome Job]