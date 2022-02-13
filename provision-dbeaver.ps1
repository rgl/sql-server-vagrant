# install the SQL Server JDBC driver.
# see https://community.chocolatey.org/packages/sqljdbc
choco install -y sqljdbc --version 10.2.0.0

# install DBeaver.
choco install -y dbeaver

# configure DBeaver.
$sqljdbcHome = (Resolve-Path 'C:\Program Files\Microsoft JDBC DRIVER*\sqljdbc*\enu').Path
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
