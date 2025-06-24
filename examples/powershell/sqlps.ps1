. .\common.ps1

Write-Host 'SQL Server Version:'
(Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER_INSTANCE -Query 'select @@version as value').value

Write-Host 'SQL Server User Name (integrated Windows authentication credentials):'
(Invoke-Sqlcmd -ServerInstance $env:SQL_SERVER_INSTANCE -Query 'select suser_name() as value').value

Write-Host 'SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):'
(Invoke-Sqlcmd -ServerInstance 'localhost,1433' -Username alice.doe -Password HeyH0Password -Query 'select suser_name() as value').value
