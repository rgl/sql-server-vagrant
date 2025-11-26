. ./provision-sql-server-common.ps1

function Get-StringSha256Hash {
    param (
        [string]$InputString
    )
    $stringBytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($stringBytes)
    $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
    return $hashString.ToLower()
}

# install sql server.
# see https://www.microsoft.com/en-us/sql-server/sql-server-downloads
# see https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver17
# see https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/SQLServer/2022/Express/
# see https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/SQLServer/2022/Developer/
if ($env:SQL_SERVER_EDITION -eq 'EXPRESS') {
    $archiveUrl = 'https://download.microsoft.com/download/7ab8f535-7eb8-4b16-82eb-eca0fa2d38f3/SQL2025-SSEI-Expr.exe'
    $mediaPath = "C:\vagrant\tmp\EXPRESS-$(Get-StringSha256Hash $archiveUrl)"
    $setupPath = "c:\tmp\EXPRESS-$(Get-StringSha256Hash $archiveUrl)\setup.exe"

    # download setup.
    if (!(Test-Path $setupPath)) {
        if (!(Test-Path $mediaPath)) {
            mkdir $mediaPath | Out-Null
        }
        $archiveName = Split-Path -Leaf $archiveUrl
        $archivePath = "$mediaPath\$archiveName"
        if (!(Test-Path $archivePath)) {
            Write-Host "Downloading $archiveName SQL Server $env:SQL_SERVER_EDITION Bootstrap Installer..."
            (New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
        }
        $sfxPath = "$mediaPath\SQL*ENU.exe"
        if (!(Test-Path $sfxPath)) {
            Write-Host "Downloading SQL Server $env:SQL_SERVER_EDITION setup..."
            &$archivePath `
                /ENU `
                /LANGUAGE=en-US `
                /ACTION=Download `
                /MEDIAPATH="$mediaPath" `
                /MEDIATYPE=Core `
                /QUIET `
                /VERBOSE `
                | Out-String -Stream
            if ($LASTEXITCODE) {
                throw "failed with exit code $LASTEXITCODE"
            }
        }
        Write-Host "Extracting SQL Server $env:SQL_SERVER_EDITION setup..."
        &$sfxPath `
            /Q `
            /X:"$(Split-Path -Parent $setupPath)" `
            /VERBOSE `
            | Out-String -Stream
        if ($LASTEXITCODE) {
            throw "failed with exit code $LASTEXITCODE"
        }
    }

    # install.
    # NB this cannot be executed from a network share (e.g. c:\vagrant).
    Write-Host "Installing SQL Server $env:SQL_SERVER_EDITION..."
    &$setupPath `
        /IACCEPTSQLSERVERLICENSETERMS `
        /QUIET `
        /ACTION=Install `
        /INSTANCEID=$env:SQL_SERVER_INSTANCE_NAME `
        /INSTANCENAME=$env:SQL_SERVER_INSTANCE_NAME `
        /UPDATEENABLED=False `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
} elseif ($env:SQL_SERVER_EDITION -in @('STANDARD-DEVELOPER', 'ENTERPRISE-DEVELOPER')) {
    $archiveUrl = 'https://download.microsoft.com/download/4ba126fc-a6a0-4810-80e9-c0182d3e1f62/SQL2025-SSEI-EntDev.exe'
    $mediaPath = "C:\vagrant\tmp\DEVELOPER-$(Get-StringSha256Hash $archiveUrl)"
    $setupPath = "c:\tmp\DEVELOPER-$(Get-StringSha256Hash $archiveUrl)\setup.exe"
    $productKey = if ($env:SQL_SERVER_EDITION -eq 'STANDARD-DEVELOPER') {
        '33333-00000-00000-00000-00000'
    } else {
        '22222-00000-00000-00000-00000'
    }

    # download setup.
    if (!(Test-Path $setupPath)) {
        if (!(Test-Path $mediaPath)) {
            mkdir $mediaPath | Out-Null
        }
        $archiveName = Split-Path -Leaf $archiveUrl
        $archivePath = "$mediaPath\$archiveName"
        if (!(Test-Path $archivePath)) {
            Write-Host "Downloading $archiveName SQL Server $env:SQL_SERVER_EDITION Bootstrap Installer..."
            (New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
        }
        $sfxPath = "$mediaPath\SQL*ENU.exe"
        if (!(Test-Path $sfxPath)) {
            Write-Host "Downloading SQL Server $env:SQL_SERVER_EDITION setup..."
            &$archivePath `
                /ENU `
                /LANGUAGE=en-US `
                /ACTION=Download `
                /MEDIAPATH="$mediaPath" `
                /MEDIATYPE=CAB `
                /QUIET `
                /VERBOSE `
                | Out-String -Stream
            if ($LASTEXITCODE) {
                throw "failed with exit code $LASTEXITCODE"
            }
        }
        Write-Host "Extracting SQL Server $env:SQL_SERVER_EDITION setup..."
        &$sfxPath `
            /Q `
            /X:"$(Split-Path -Parent $setupPath)" `
            /VERBOSE `
            | Out-String -Stream
        if ($LASTEXITCODE) {
            throw "failed with exit code $LASTEXITCODE"
        }
    }

    # install.
    # NB this cannot be executed from a network share (e.g. c:\vagrant).
    Write-Host "Installing SQL Server $env:SQL_SERVER_EDITION..."
    &$setupPath `
        /IACCEPTSQLSERVERLICENSETERMS `
        /QUIET `
        /ACTION=Install `
        /PID=$productKey `
        /FEATURES=SQL `
        /INSTANCEID=$env:SQL_SERVER_INSTANCE_NAME `
        /INSTANCENAME=$env:SQL_SERVER_INSTANCE_NAME `
        /UPDATEENABLED=False `
        /SQLSYSADMINACCOUNTS="$env:USERDOMAIN\$env:USERNAME" `
        | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "failed with exit code $LASTEXITCODE"
    }
} else {
    throw "unsupported sql server edition: $env:SQL_SERVER_EDITION"
}

# update $env:PSModulePath to include the modules installed by recently installed package.
$env:PSModulePath = "$([Environment]::GetEnvironmentVariable('PSModulePath', 'User'));$([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine'))"

# install the Sql Server PowerShell Module.
# see https://www.powershellgallery.com/packages/Sqlserver
# see https://learn.microsoft.com/en-us/powershell/module/sqlserver/?view=sqlserver-ps
# see https://learn.microsoft.com/en-us/powershell/sql-server/download-sql-server-ps-module?view=sqlserver-ps
Write-Host "Installing the SqlServer PowerShell module..."
Install-Module SqlServer -AllowClobber -RequiredVersion 22.4.5.1

# load the SQL Server PowerShell provider and related Smo .NET assemblies.
Import-Module SqlServer

# allow remote TCP/IP connections.
# see http://stefanteixeira.com/2015/09/01/automating-sqlserver-config-with-powershell-wmi/
Write-Host 'Enabling remote TCP/IP access (port 1433)...'
$wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'
$tcp = $wmi.GetSmoObject("ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='$env:SQL_SERVER_INSTANCE_NAME']/ServerProtocol[@Name='Tcp']")
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
Restart-Service $env:SQL_SERVER_SERVICE_NAME -Force

Write-Host 'Enabling Mixed Mode Authentication...'
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $env:SQL_SERVER_INSTANCE
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
    $login = New-Object Microsoft.SqlServer.Management.Smo.Login $env:SQL_SERVER_INSTANCE,$_
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
    $login = New-Object Microsoft.SqlServer.Management.Smo.Login $env:SQL_SERVER_INSTANCE,"$env:COMPUTERNAME\$_"
    $login.LoginType = 'WindowsUser'
    $login.PasswordPolicyEnforced = $false
    $login.PasswordExpirationEnabled = $false
    $login.Create()
}

# restart it to be able to use the recently added users.
Restart-Service $env:SQL_SERVER_SERVICE_NAME -Force

Write-Host 'Creating the firewall rule to allow inbound TCP/IP access to the SQL Server port 1443...'
New-NetFirewallRule `
    -Name 'SQL-SERVER-In-TCP' `
    -DisplayName 'SQL Server (TCP-In)' `
    -Direction Inbound `
    -Enabled True `
    -Protocol TCP `
    -LocalPort 1433 `
    | Out-Null
