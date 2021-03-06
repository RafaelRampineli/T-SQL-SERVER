--Permissões expliticas de objetos no DB

-- PERMISSOES EXPLICITAS DO USUARIO
SELECT
dp.Class,
dps1.Name As Grantee,
dps2.Name As Grantor,
so.Name,
so.Type,
dp.Permission_Name,
dp.State_Desc
FROM sys.database_permissions AS dp
JOIN Sys.Database_Principals dps1
ON dp.grantee_Principal_ID = dps1.Principal_ID
JOIN Sys.Database_Principals dps2
ON dp.grantor_Principal_ID = dps2.Principal_ID
JOIN sys.objects AS so
ON dp.major_id = so.object_id
--WHERE dps1.Name LIKE '%user_name%'
ORDER BY 2

-- DATABASE_ROLES E USUARIOS
select rp.name as database_role, mp.name as database_user
from sys.database_role_members drm
  join sys.database_principals rp on (drm.role_principal_id = rp.principal_id)
  join sys.database_principals mp on (drm.member_principal_id = mp.principal_id)
order by rp.name

/*
EXEC sys.sp_addrolemember
	@rolename = NULL, 
    @membername = NULL 

EXEC sys.sp_droprolemember
	@rolename = NULL, 
    @membername = NULL 
*/
