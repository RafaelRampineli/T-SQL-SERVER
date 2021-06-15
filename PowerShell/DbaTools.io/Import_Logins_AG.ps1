$AGLSN = 'AG-Name'
 
$primaryReplica =    Get-DbaAgReplica -SqlInstance $AGLSN | Where Role -eq Primary
$secondaryReplicas = Get-DbaAgReplica -SqlInstance $AGLSN | Where Role -eq Secondary
 

$primaryReplica 
     
$LoginsOnPrimary = (Get-DbaLogin -SqlInstance $primaryReplica.Name)
     
$secondaryReplicas | ForEach-Object {
        
    $LoginsOnSecondary = (Get-DbaLogin -SqlInstance $_.Name)
     
    $diff = $LoginsOnPrimary | Where-Object Name -notin ($LoginsOnSecondary.Name) 
}  