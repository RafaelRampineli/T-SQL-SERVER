--Gera script com todos usuários do Db para dar auto fix. (Executar em cada Db)
select 'EXEC sp_change_users_login ''auto_fix'', ' + CHAR(39) + name + CHAR(39) + + CHAR(13) + CHAR(10)+ 'GO'
from sys.sysusers
where islogin = 1 and issqluser =1 and hasdbaccess = 1 and sid > 0x01

/* O SCRIPT ACIMA FOI DEPRECIADO E EM ALGUMAS VERSOES NAO IRÁ FUNCIONAR. */

/* SELECIONA OS USERS ORFÃOS QUE NÃO POSSUEM LOGIN */
SELECT name, sid, principal_id
FROM sys.database_principals 
WHERE type = 'S' 
AND name NOT IN ('guest', 'INFORMATION_SCHEMA', 'sys')
AND authentication_type_desc = 'INSTANCE'
AND sid NOT IN (SELECT sid FROM sys.sql_logins WHERE type = 'S')

/*CRIAR LOGIN PARA OS USERS IDENTIFICADOS ACIMA, INFORMANDO O SID */
CREATE LOGIN [user_name]
WITH PASSWORD = [pwd] MUST_CHANGE, -- Forca alterar senha no primeiro Login
CHECK_EXPIRATION = ON,
SID = @SID

/* ALTERA O USER VINCULANDO AO LOGIN CRIADO */
ALTER USER user_name WITH LOGIN = user_name