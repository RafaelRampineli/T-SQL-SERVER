$OldInstance = 'localhost\MSSQLSERVER'
$NewInstance = 'localhost\MSSQLSERVER'

# Export current jobs to scripts
#Get-DbaAgentJob -SqlInstance $OldInstance | Where-Object {-not $_.isenabled} | ForEach-Object {Export-DbaScript $_ -Path (Join-Path -Path C:\Users\Administrator\Desktop\Jobs_Teste\DisabledJobs -Childpath "$($_.name.replace('\','$')).sql")};
#Get-DbaAgentJob -SqlInstance $OldInstance | Where-Object {$_.isenabled} | ForEach-Object {Export-DbaScript $_ -Path (Join-Path -Path C:\Users\Administrator\Desktop\Jobs_Teste\EnabledJobs -Childpath "$($_.name.replace('\','$')).sql")};

# Get only the enabled job
$JobsToCopy = Get-DbaAgentJob -SqlInstance $OldInstance -ExcludeDisabledJobs;

# Copy the Operator(s) from the existing server
Copy-DbaAgentOperator -Source $oldinstance -Destination $newinstance;

# Copy only the enabled jobs and disable on the new server
Copy-DbaAgentJob -Source $OldInstance -Destination $NewInstance -Job $JobsToCopy.Name -verbose -DisableOnDestination;