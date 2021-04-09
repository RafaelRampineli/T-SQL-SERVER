# Script must be executed inside directory $ScriptDirectory

$dbServer = "ServerName"
$ScriptDirectory = 'Directory'
Import-Module SQLPS
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $dbServer

try {
 $file = dir $ScriptDirectory
 foreach ($f in $file) {
  $s = Get-Content $f -Raw
  $srv.ConnectionContext.ExecuteNonQuery($s);
 }
}
catch {
 $error[0].Exception
}
