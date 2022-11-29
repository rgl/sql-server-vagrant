. .\common.ps1

$serverInstance = '.\SQLEXPRESS'
$databaseName = 'TheSimpsons'

Write-Host "Creating the $databaseName database..."
$database = New-Object Microsoft.SqlServer.Management.Smo.Database $serverInstance,$databaseName
$database.Create()
$database.Refresh()

Write-Host "Creating the db_executor role in the $databaseName database..."
$role = New-Object Microsoft.SqlServer.Management.Smo.DatabaseRole $database,'db_executor'
$role.Create()
$rolePermissions = New-Object Microsoft.SqlServer.Management.Smo.DatabasePermissionSet
$rolePermissions.Add([Microsoft.SqlServer.Management.Smo.DatabasePermission]::Execute) | Out-Null
$database.Grant($rolePermissions, $role.Name)

Write-Host 'Creating databases users and assigning roles...'
@{
    'carol.doe' = @('db_datawriter', 'db_datareader', 'db_executor')
    'eve.doe'   = @('db_datareader', 'db_executor')
}.GetEnumerator() | ForEach-Object {
    $userName = $_.Name
    $userRoles = $_.Value

    Write-Host "Creating the $userName database user..."
    $user = New-Object Microsoft.SqlServer.Management.Smo.User $database,$userName
    $user.Login = $userName
    $user.Create()

    $userRoles | ForEach-Object {
        Write-Host "Adding the $userName user to the $_ database role..."
        $role = $database.Roles[$_]
        $role.AddMember($userName)
        $role.Alter()
    }
}

Write-Host "Creating the $databaseName schema..."
$r = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -Query @'
create table Character(
    Id nvarchar(255) not null,
    Name nvarchar(80) not null,
    Gender varchar(10) not null);
go
create procedure GetTotalCharactersByGender
    @gender varchar(10)
as
    set nocount on;
    select
        count(*) as Total
    from
        Character
    where
        Gender=@gender;
go
'@

Write-Host 'Getting The Simpsons characters...'
$q = @'
select ?s ?name ?gender where {
    wd:Q886 wdt:P674 ?s.
    ?s rdfs:label ?name filter(lang(?name) = 'en').
    ?s wdt:P21 ?_gender.
    ?_gender rdfs:label ?gender filter(lang(?gender) = 'en').
}
order by asc(?name)
'@
$r = Invoke-RestMethod "https://query.wikidata.org/sparql?query=$([Uri]::EscapeDataString($q))&format=json"
$theSimpsons = $r.results.bindings | ForEach-Object {
    New-Object PSObject -Property @{
        Id = $_.s.value
        Name = $_.name.value
        Gender = $_.gender.value}}

Write-Host "Populating the $databaseName database..."
$connection = New-Object System.Data.SqlClient.SqlConnection "Server=$serverInstance; Database=$databaseName; Integrated Security=true"
$connection.Open()
try {
    $command = $connection.CreateCommand()
    try {
        $idParameter = $command.Parameters.Add('@Id', [System.Data.SqlDbType]::NVarChar, 255)
        $nameParameter = $command.Parameters.Add('@Name', [System.Data.SqlDbType]::NVarChar, 80)
        $genderParameter = $command.Parameters.Add('@Gender', [System.Data.SqlDbType]::VarChar, 10)
        $command.CommandText = 'insert into Character(Id, Name, Gender) values(@Id, @Name, @Gender)'
        $command.Prepare()
        $theSimpsons | ForEach-Object {
            $idParameter.Value = $_.Id
            $nameParameter.Value = $_.Name
            $genderParameter.Value = $_.Gender
            $rowsAffected = $command.ExecuteNonQuery()
            if ($rowsAffected -ne 1) {
                throw "failed to insert Character into the database"
            }
        }
    }
    finally {
        $command.Dispose()
    }
} finally {
    $connection.Dispose()
}

# execute the GetTotalCharactersByGender stored procedure.
'male','female' | ForEach-Object {
    $r = Invoke-Sqlcmd `
        -ServerInstance $serverInstance `
        -Database $databaseName `
        -Username eve.doe `
        -Password HeyH0Password `
        -Query "exec GetTotalCharactersByGender '$_'"
    Write-Host "There are $($r.Total) $_ characters on the $databaseName database"
}
