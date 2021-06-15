$SourceInstance = 'localhost\MSSQLSERVER'
$DestinationInstance = 'localhost\MSSQLSERVER'

$LoginsSource =      Get-DbaLogin -SqlInstance $SourceInstance
$LoginsDestination = Get-DbaLogin -SqlInstance $DestinationInstance
     
$diff = $LoginsSource | Where-Object Name -notin ($LoginsDestination.Name)

$diff.Name

if($diff) {
    Copy-DbaLogin -Source $SourceInstance -Destination $DestinationInstance -Login $diff.Name
}


<# APÓS REALIZAR A IMPORTAÇÃO ENTRE AS INSTÂNCIAS, REALIZAR A VALIDAÇÃO DO SID ATRAVÉS DO SELECT ABAIXO (SERÃO IGUAIS)

select sp.name as login,
	   sp.sid,
       sp.type_desc as login_type,
       sp.create_date,
       sp.modify_date,
       case when sp.is_disabled = 1 then 'Disabled'
            else 'Enabled' end as status
from sys.server_principals sp
where sp.type_desc = 'SQL_LOGIN'
order by sp.name;
#>  
    

    
