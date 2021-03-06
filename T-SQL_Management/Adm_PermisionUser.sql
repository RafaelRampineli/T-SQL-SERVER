-- SCRIPT OLD, NECESSITA DE ALGUMAS REVISÕES
SELECT  
	  dp.NAME AS principal_name
	, dp.type_desc AS principal_type_desc
    , o.NAME AS OBJECT_NAME
	, p.permission_name
	, p.state_desc AS permission_state_desc
	, *
  FROM sys.database_permissions p
  LEFT OUTER JOIN sys.all_objects o
    ON p.major_id = o.OBJECT_ID
 INNER JOIN sys.database_principals dp
    ON p.grantee_principal_id = dp.principal_id
 ORDER BY principal_name

SELECT 
	  SSP.name AS [Login Name]
	, SSP.type_desc AS [Login Type]
	, UPPER(SSPS.name) AS [Server Role]
	, *
  FROM sys.server_principals SSP 
 INNER JOIN sys.server_role_members SSRM
    ON SSP.principal_id = SSRM.member_principal_id 
 INNER JOIN sys.server_principals SSPS 
    ON SSRM.role_principal_id = SSPS.principal_id
GO

--USE msdb
--go

SELECT 
      SDP.name AS [User Name]
	, SDP.type_desc AS [User Type]
	, UPPER(SDPS.name) AS [Database Role]
	, *
  FROM sys.database_principals SDP 
  LEFT JOIN sys.database_role_members SDRM
    ON SDP.principal_id = SDRM.member_principal_id 
  LEFT JOIN sys.database_principals SDPS 
    ON SDRM.role_principal_id = SDPS.principal_id
 ORDER BY SDP.type_desc DESC
GO


SELECT * FROM sys.database_principals

SELECT * 
  FROM sys.fn_builtin_permissions(DEFAULT) 
 WHERE permission_name = 'SELECT';


EXEC sp_helpuser