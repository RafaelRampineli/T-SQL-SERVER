;WITH CPU_LOGIN
AS
(
	SELECT sp.loginame as Login,  SUM(cpu) CPU
	FROM sys.dm_exec_requests er
	INNER JOIN sys.sysprocesses sp ON er.session_id = sp.spid
	INNER JOIN sys.dm_exec_connections CN ON CN.session_id = er.session_id
	group by sp.loginame
) 

SELECT Login, CAST(CPU * 1.0 / SUM(CPU) OVER() * 100.0 AS DECIMAL(5, 2)) AS CPU 
FROM CPU_LOGIN
ORDER BY CPU