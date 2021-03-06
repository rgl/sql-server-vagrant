# install python.
choco install -y python --version 3.8.5

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt

# run the example.
python main.py
