# install the odbc driver.
# NB when you change this version, you might also need to update the connection
#    string in main.py (to a name returned by the Get-OdbcDriver cmdlet).
# see https://community.chocolatey.org/packages/sqlserver-odbcdriver
choco install -y sqlserver-odbcdriver --version 18.4.1.1

# list the installed odbc drivers.
Get-OdbcDriver -Platform '64-bit' `
    | Sort-Object Name `
    | Format-Table Name

# install python.
# see https://community.chocolatey.org/packages/python
choco install -y python --version 3.14.0

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# run the example.
python main.py
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
