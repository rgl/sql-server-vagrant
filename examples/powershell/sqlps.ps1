# NB to be able to connect to SQL Server you must install the sql2014-powershell
# chocolatey package. We don't do it here because this machine already has the
# sqlps PowerShell module (installed by the SQL Server installer).

# load the SQL Server PowerShell provider and related Smo .NET assemblies.
Push-Location                               # save the current location...
Import-Module Sqlps -DisableNameChecking    # ... because importing the module changes the current directory to "SQLSERVER:"
Pop-Location                                # ... and we do not want that.

Write-Host 'SQL Server Version:'
(Invoke-Sqlcmd -ServerInstance .\SQLEXPRESS -Query 'select @@version as value').value

Write-Host 'SQL Server User Name (integrated Windows authentication credentials):'
(Invoke-Sqlcmd -ServerInstance .\SQLEXPRESS -Query 'select suser_name() as value').value

Write-Host 'SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection):'
(Invoke-Sqlcmd -ServerInstance 'localhost,1433' -Username alice.doe -Password HeyH0Password -Query 'select suser_name() as value').value
