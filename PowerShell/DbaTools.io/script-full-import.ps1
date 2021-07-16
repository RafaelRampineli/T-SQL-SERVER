$InstanciaOrigem = 'IPVM\MSSQLSERVER' 
$InstanciaDestino = 'IPVM\MSSQLSERVER'



# IMPORTANDO OPERATOR
Copy-DbaAgentOperator -Source $InstanciaOrigem -Destination $InstanciaDestino -Force;

# IMPORTANDO JOBS
Copy-DbaAgentJob -Source $InstanciaOrigem -Destination $InstanciaDestino -Force

# IMPORTANDO LOGINS EXCETO LOGINS DOMINIO NT SERVICE E OS LISTADOS
$ExcludeLogins = 'NT AUTHORITY\ANONYMOUS LOGON', 'NT AUTHORITY\SYSTEM', '##MS_PolicyEventProcessingLogin##', '##MS_PolicyTsqlExecutionLogin##', 'WIN2019STD-SQL2\Administrator'
Copy-DbaLogin -Source $InstanciaOrigem -Destination $InstanciaDestino -ExcludeSystemLogins -ExcludeLogin $ExcludeLogins -Force

# IMPORTANDO LINKEDSERVERS
Copy-DbaLinkedServer -Source $InstanciaOrigem -Destination $InstanciaDestino -Force

# IMPORTANDO Mail Profiles, Accounts, Mail Servers e  Mail Server Configs
Copy-DbaDbMail -Source $InstanciaOrigem -Destination $InstanciaDestino

