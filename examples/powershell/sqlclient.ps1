. .\common.ps1

Write-Host 'SQL Server Version:'
Write-Host (SqlExecuteScalar 'Server=.\SQLEXPRESS; Database=master; Integrated Security=true' 'select @@version')

Write-Host 'SQL Server User Name (integrated Windows authentication credentials) with .NET SqlClient:'
Write-Host (SqlExecuteScalar 'Server=.\SQLEXPRESS; Database=master; Integrated Security=true' 'select suser_name()')

Write-Host 'SQL Server User Name (alice.doe; username/password credentials; TCP/IP connection) with .NET SqlClient:'
Write-Host (SqlExecuteScalar 'Server=localhost,1433; User ID=alice.doe; Password=HeyH0Password; Database=master' 'select suser_name()')
