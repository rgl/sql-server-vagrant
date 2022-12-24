# install the SQL Server JDBC driver.
# see https://community.chocolatey.org/packages/sqljdbc
# see https://github.com/Microsoft/mssql-jdbc
$version = '11.2.0.0'
choco install -y sqljdbc --version $version
# remove invalid characters from the installation path.
# see https://github.com/dgalbraith/chocolatey-packages/issues/448
$brokenPath = Resolve-Path 'C:\Program Files\Microsoft JDBC DRIVER*\sqljdbc*enu'
$path = Join-Path (Split-Path -Parent $brokenPath) "sqljdbc_${version}_enu"
Rename-Item $brokenPath $path

# install DBeaver.
# see https://community.chocolatey.org/packages/dbeaver
choco install -y dbeaver --version 22.3.0

# configure DBeaver.
$sqljdbcHome = (Resolve-Path 'C:\Program Files\Microsoft JDBC DRIVER*\sqljdbc*').Path
$SQLJDBC_JAR_PATH = Resolve-Path "$sqljdbcHome\mssql-jdbc-*.jre11.jar"
$SQLJDBC_DLL_PATH = Resolve-Path "$sqljdbcHome\auth\x64\mssql-jdbc_auth-*.x64.dll"
$workspaceHome = "$env:APPDATA\DBeaverData\workspace6"
$configHome = "$workspaceHome\.metadata\.config"
$projectHome = "$workspaceHome\General\.dbeaver"
mkdir -Force $configHome,$projectHome | Out-Null
[IO.File]::WriteAllText(
    "$configHome\drivers.xml",
    ([IO.File]::ReadAllText("$PWD\provision-dbeaver-drivers.xml") `
        -replace '@@SQLJDBC_JAR_PATH@@',$SQLJDBC_JAR_PATH `
        -replace '@@SQLJDBC_DLL_PATH@@',$SQLJDBC_DLL_PATH))
Copy-Item provision-dbeaver-data-sources.json "$projectHome\data-sources.json"
