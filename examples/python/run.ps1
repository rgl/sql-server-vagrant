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
