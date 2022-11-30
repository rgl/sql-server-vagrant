# install SQL Server.
# see https://community.chocolatey.org/packages/sql-server-express
choco install -y sql-server-express --version 2022.16.0.1000 # SQL Server 2022 Express.

# update $env:PSModulePath to include the modules installed by recently installed Chocolatey packages.
$env:PSModulePath = "$([Environment]::GetEnvironmentVariable('PSModulePath', 'User'));$([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine'))"

# load the SQL Server PowerShell provider and related Smo .NET assemblies.
Push-Location                               # save the current location...
Import-Module Sqlps -DisableNameChecking    # ... because importing the module changes the current directory to "SQLSERVER:"
Pop-Location                                # ... and we do not want that.

# allow remote TCP/IP connections.
# see http://stefanteixeira.com/2015/09/01/automating-sqlserver-config-with-powershell-wmi/
Write-Host 'Enabling remote TCP/IP access (port 1433)...'
$wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
$tcp = $wmi.GetSmoObject("ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='SQLEXPRESS']/ServerProtocol[@Name='Tcp']")
$tcp.IsEnabled = $true
$tcp.IPAddresses | Where-Object { $_.Name -eq 'IPAll' } | ForEach-Object {
    foreach ($property in $_.IPAddressProperties) {
        switch ($property.Name) {
            'Enabled' { $property.Value = $true }
            'TcpPort' { $property.Value = '1433' }
            'TcpDynamicPorts' { $property.Value = '0' }
        }
    }
}
$tcp.Alter()
Restart-Service 'MSSQL$SQLEXPRESS' -Force

Write-Host 'Enabling Mixed Mode Authentication...'
$instanceName = '.\SQLEXPRESS'
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $instanceName
$server.Settings.LoginMode = 'Mixed'
$server.Alter()

# create a bunch of test users.
$testUsers = @(
    'alice.doe'
    'bob.doe'
    'carol.doe'
    'dave.doe'
    'eve.doe'
    'frank.doe'
    'grace.doe'
    'henry.doe'
)
# create SQL Server accounts for the women.
Write-Host 'Creating SQL Server Users...'
$testUsers | ForEach-Object {$i=0} { if (![bool]($i++ % 2)) {$_}} | ForEach-Object {
    $login = New-Object Microsoft.SqlServer.Management.Smo.Login $instanceName,$_
    $login.LoginType = 'SqlLogin'
    $login.PasswordPolicyEnforced = $false
    $login.PasswordExpirationEnabled = $false
    $login.Create('HeyH0Password')
}
# grant sysadmin permissions to alice.doe.
$sysadminRole = $server.Roles['sysadmin']
$sysadminRole.AddMember('alice.doe')
$sysadminRole.Alter()
# create Windows accounts for the men.
Write-Host 'Creating Windows Users and adding them to SQL Server...'
$testUsers | ForEach-Object {$i=0} { if ([bool]($i++ % 2)) {$_}} | ForEach-Object {
    # see the ADS_USER_FLAG_ENUM enumeration at https://msdn.microsoft.com/en-us/library/aa772300(v=vs.85).aspx
    $AdsScript              = 0x00001
    $AdsAccountDisable      = 0x00002
    $AdsNormalAccount       = 0x00200
    $AdsDontExpirePassword  = 0x10000
    $user = ([ADSI]'WinNT://.').Create('User', $_)
    $user.Put('FullName', (Get-Culture).TextInfo.ToTitleCase(($_ -replace '\.',' ')))
    $user.Put('Description', 'Test Account')
    $user.Userflags = $AdsNormalAccount -bor $AdsDontExpirePassword
    $user.SetPassword('HeyH0Password')
    $user.SetInfo()
    # add the user to the Users group.
    ([ADSI]'WinNT://./Users,Group').Add("WinNT://$_,User")
    # add the Windows user to SQL Server.
    $login = New-Object Microsoft.SqlServer.Management.Smo.Login $instanceName,"$env:COMPUTERNAME\$_"
    $login.LoginType = 'WindowsUser'
    $login.PasswordPolicyEnforced = $false
    $login.PasswordExpirationEnabled = $false
    $login.Create()
}

# restart it to be able to use the recently added users.
Restart-Service 'MSSQL$SQLEXPRESS' -Force

Write-Host 'Creating the firewall rule to allow inbound TCP/IP access to the SQL Server port 1443...'
New-NetFirewallRule `
    -Name 'SQL-SERVER-In-TCP' `
    -DisplayName 'SQL Server (TCP-In)' `
    -Direction Inbound `
    -Enabled True `
    -Protocol TCP `
    -LocalPort 1433 `
    | Out-Null
