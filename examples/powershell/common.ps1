. ../../provision-sql-server-common.ps1

# load the SQL Server PowerShell provider and related Smo .NET assemblies.
Import-Module SqlServer

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
