. .\common.ps1

Write-Host 'SQL Server Version:'
Write-Host (SqlExecuteScalar "Server=$env:SQL_SERVER_INSTANCE; Database=master; Integrated Security=true; Application Name=PowerShell SqlClient Example" 'select @@version')

Write-Host 'SQL Server Client Application Name:'
Write-Host (SqlExecuteScalar "Server=$env:SQL_SERVER_INSTANCE; Database=master; Integrated Security=true; Application Name=PowerShell SqlClient Example" 'select app_name()')

Write-Host 'SQL Server User Name (integrated Windows authentication credentials) with .NET SqlClient:'
Write-Host (SqlExecuteScalar "Server=$env:SQL_SERVER_INSTANCE; Database=master; Integrated Security=true; Application Name=PowerShell SqlClient Example" 'select suser_name()')

Write-Host 'SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection) with .NET SqlClient:'
Write-Host (SqlExecuteScalar "Server=$env:SQL_SERVER_INSTANCE,1433; User ID=alice.doe; Password=HeyH0Password; Database=master; Application Name=PowerShell SqlClient Example" 'select suser_name()')
