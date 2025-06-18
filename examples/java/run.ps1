# use the Windows Trust store (set to $false to use java cacerts).
$useWindowsTrustStore = $true

# install dependencies.
# see https://community.chocolatey.org/packages/temurin17
# see https://community.chocolatey.org/packages/gradle
choco install -y temurin17
choco install -y gradle --version 8.14.2

# install the SQL Server JDBC Auth driver.
# see https://github.com/Microsoft/mssql-jdbc
$archiveVersion = '12.2.0'
$archiveUrl = "https://github.com/microsoft/mssql-jdbc/releases/download/v$archiveVersion/mssql-jdbc_auth.zip"
$archivePath = "$env:TEMP\mssql-jdbc_auth-$archiveVersion.zip"
if (Test-Path $archivePath) {
    Remove-Item $archivePath | Out-Null
}
(New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
$jdbcAuthPath = 'C:\Program Files\mssql-jdbc_auth'
if (Test-Path $jdbcAuthPath) {
    Remove-Item -Recurse -Force $jdbcAuthPath | Out-Null
}
Expand-Archive $archivePath $jdbcAuthPath

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# add our Example CA certificate to the default java trust store.
if (!$useWindowsTrustStore) {
    @(
        'C:\Program Files\*\*\lib\security\cacerts'
    ) | ForEach-Object {Get-ChildItem $_} | ForEach-Object {
        $keyStore = $_
        $alias = 'Example CA'
        $keytool = Resolve-Path "$keyStore\..\..\..\bin\keytool.exe"
        $keytoolOutput = &$keytool `
            -noprompt `
            -list `
            -storepass changeit `
            -cacerts `
            -alias "$alias"
        if ($keytoolOutput -match 'keytool error: java.lang.Exception: Alias .+ does not exist') {
            Write-Host "Adding $alias to the java $keyStore keystore..."
            # NB we use Start-Process because keytool writes to stderr... and that
            #    triggers PowerShell to fail, so we work around this by redirecting
            #    stdout and stderr to a temporary file.
            # NB keytool exit code is always 1, so we cannot rely on that.
            Start-Process `
                -FilePath $keytool `
                -ArgumentList `
                    '-noprompt',
                    '-import',
                    '-trustcacerts',
                    '-storepass changeit',
                    '-cacerts',
                    "-alias `"$alias`"",
                    '-file c:\vagrant\tmp\ca\example-ca-crt.der' `
                -RedirectStandardOutput "$env:TEMP\keytool-stdout.txt" `
                -RedirectStandardError "$env:TEMP\keytool-stderr.txt" `
                -NoNewWindow `
                -Wait
            $keytoolOutput = Get-Content -Raw "$env:TEMP\keytool-stdout.txt","$env:TEMP\keytool-stderr.txt"
            if ($keytoolOutput -notmatch 'Certificate was added to keystore') {
                Write-Host $keytoolOutput
                throw "failed to import Example CA"
            }
        } elseif ($LASTEXITCODE) {
            Write-Host $keytoolOutput
            throw "failed to list Example CA with exit code $LASTEXITCODE"
        }
    }
}

# build into a fat jar.
# NB gradle build would also work, but having a fat jar is nicer for distribution.
gradle `
    --no-daemon `
    --no-watch-fs `
    --warning-mode all `
    shadowJar
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# run the example.
# NB gradle run would also work, but this shows how a user would use the fat jar.
# NB for using the integrated authentication we must have sqljdbc_auth.dll in the
#    current directory, %PATH%, or inside one of the directories defined in the
#    java.library.path java property (as done here; it points to the drivers
#    installed from github above).
$javaLibraryPath = "$jdbcAuthPath\x64"
java `
    "-Djava.library.path=$javaLibraryPath" `
    $(if ($useWindowsTrustStore) {'-Djavax.net.ssl.trustStoreType=Windows-ROOT'} else {$null}) `
    -jar build/libs/example-1.0.0-all.jar
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
