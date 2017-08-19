# install python.
choco install -y python

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt

# run the example.
python main.py
