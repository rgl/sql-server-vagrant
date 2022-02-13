# install python.
# see https://community.chocolatey.org/packages/python
# TODO upgrade to python 3.10+ when https://github.com/mkleehammer/pyodbc/issues/981 is fixed.
choco install -y python --version 3.8.10

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt

# run the example.
python main.py
