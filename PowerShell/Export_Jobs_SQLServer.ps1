# Nome da sua máquina
$ServerNameList = "VM-DBA"

# Diretório para salvar os scripts
$OutputFolder = "C:\Jobs\"

$DoesFolderExist = Test-Path $OutputFolder
$null = if (!$DoesFolderExist){MKDIR "$OutputFolder"}

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

$objSQLConnection = New-Object System.Data.SqlClient.SqlConnection

foreach ($ServerName in $ServerNameList)
{

    Try
    {
        $objSQLConnection.ConnectionString = "Server=$ServerName;Integrated Security=SSPI;"
        Write-Host "Tentando se conectar na instância do servidor $ServerName..." -NoNewline
        $objSQLConnection.Open() | Out-Null
        Write-Host "Conectado."
        $objSQLConnection.Close()
    }
    Catch
    {
        Write-Host -BackgroundColor Red -ForegroundColor White "Falha"
        $errText = $Error[0].ToString()
        if ($errText.Contains("network-related"))
            {Write-Host "Erro de conexão à instância. Por favor, verifique o nome do servidor digitado, porta ou firewall."}

        Write-Host $errText
        
        continue

    }

    $srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $ServerName
    
    # Arquivo único com todos os jobs
    # $srv.JobServer.Jobs | foreach {$_.Script() + "GO`r`n"} | out-file "$OutputFolder\jobs.sql"

    # Um arquivo por job
    $srv.JobServer.Jobs | foreach-object -process {out-file -filepath $("$OutputFolder\" + $($_.Name -replace "\\", "") + ".sql") -inputobject $_.Script() }

}

