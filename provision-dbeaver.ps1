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
choco install -y dbeaver

# configure DBeaver.
$sqljdbcHome = (Resolve-Path 'C:\Program Files\Microsoft JDBC DRIVER*\sqljdbc*').Path
$workspaceHome = "$env:USERPROFILE\.dbeaver4"
$metadataHome = "$workspaceHome\.metadata"
$pluginsHome = "$metadataHome\.plugins"
$projectHome = "$workspaceHome\General"
mkdir -Force "$pluginsHome\org.jkiss.dbeaver.core",$projectHome | Out-Null
[IO.File]::WriteAllText(
    "$pluginsHome\org.jkiss.dbeaver.core\drivers.xml",
    ([IO.File]::ReadAllText("$PWD\provision-dbeaver-drivers.xml") `
        -replace '@@SQLJDBC_HOME@@',$sqljdbcHome))
Copy-Item provision-dbeaver-data-sources.xml "$projectHome\.dbeaver-data-sources.xml"
