# NB to be able to connect to SQL Server you must install the sql2014-powershell
# chocolatey package. We don't do it here because this machine already has the
# sqlps PowerShell module (installed by the SQL Server installer).

# load the SQL Server PowerShell provider and related Smo .NET assemblies.
Push-Location                               # save the current location...
Import-Module Sqlps -DisableNameChecking    # ... because importing the module changes the current directory to "SQLSERVER:"
Pop-Location                                # ... and we do not want that.

# helper function to execute a scalar returning sql statement.
function SqlExecuteScalar($connectionString, $sql) {
    $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $connection.Open()
    try {
        $command = $connection.CreateCommand()
        try {
            $command.CommandText = $sql
            return $command.ExecuteScalar()
        }
        finally {
            $command.Dispose()
        }
    } finally {
        $connection.Dispose()
    }
}
