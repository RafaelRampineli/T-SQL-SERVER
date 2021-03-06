--Mover arquivos de diretório
DECLARE @varNewPath VARCHAR(200) = 'c:\...'

SELECT 'ALTER DATABASE tempdb MODIFY FILE (name = '+name+' , filename =  '''+@varNewPath+
    RIGHT(physical_name, CHARINDEX('\', REVERSE(physical_name)) -1)+''')' SQLcmd,
    physical_name localizacao_atual
        --name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'tempdb');