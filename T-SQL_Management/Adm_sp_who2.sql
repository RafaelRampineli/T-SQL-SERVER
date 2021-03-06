DECLARE @spWho TABLE(
       SPID INT,
       Status VARCHAR(MAX),
       LOGIN VARCHAR(MAX),
       HostName VARCHAR(MAX),
       BlkBy VARCHAR(MAX),
       DBName VARCHAR(MAX),
       Command VARCHAR(MAX),
       CPUTime INT,
       DiskIO INT,
       LastBatch VARCHAR(MAX),
       ProgramName VARCHAR(MAX),
       SPID_1 INT,
       REQUESTID INT
)

INSERT INTO @spWho EXEC sp_who2

SELECT	*
		--er.*, CN.client_net_address 
FROM @spWho er
INNER JOIN sys.sysprocesses sp ON er.spID = sp.spid
INNER JOIN sys.dm_exec_connections CN ON CN.session_id = er.spID
--WHERE er.HostName = 'host_name'
WHERE er.login = 'login_name'

SELECT   
    c.session_id, c.net_transport, c.encrypt_option,   
    c.auth_scheme, s.host_name, s.program_name,   
    s.client_interface_name, s.login_name, s.nt_domain,   
    s.nt_user_name, s.original_login_name, c.connect_time,   
    s.login_time   
FROM sys.dm_exec_connections AS c  
JOIN sys.dm_exec_sessions AS s  
    ON c.session_id = s.session_id  

 
SELECT  login, count(DISTINCT spID) FROM @spWho
GROUP BY login
ORDER BY 2 DESC