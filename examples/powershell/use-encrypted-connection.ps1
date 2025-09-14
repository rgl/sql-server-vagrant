. .\common.ps1

$encryptOptionQuery = 'select encrypt_option from sys.dm_exec_connections where session_id=@@SPID'

Write-Host 'Asserting that the SQL Server connection is encrypted (Invoke-Sqlcmd; alice.doe; username/password credentials; Encrypted TCP/IP connection)...'
$encryptOption = (Invoke-Sqlcmd `
    -ServerInstance "$env:COMPUTERNAME,1433" `
    -Encrypt Strict `
    -Username alice.doe `
    -Password HeyH0Password `
    -Query $encryptOptionQuery).encrypt_option
if ($encryptOption -ne 'TRUE') {
    throw "expecting the connection encrypt_option to be TRUE but its $encryptOption"
}

Write-Host 'Asserting that the SQL Server connection is encrypted (SqlClient; alice.doe; username/password credentials; Encrypted TCP/IP connection)...'
# NB you can also use TrustServerCertificate=true for testing purposes (but never do that in production).
$encryptOption = SqlExecuteScalar "Server=$env:COMPUTERNAME,1433; Encrypt=true; User ID=alice.doe; Password=HeyH0Password; Database=master" $encryptOptionQuery
if ($encryptOption -ne 'TRUE') {
    throw "expecting the connection encrypt_option to be TRUE but its $encryptOption"
}
