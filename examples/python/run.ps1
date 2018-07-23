# install python.
# NB as of 2018-07-23 there is no pyodbc binary package for python 3.7+ so stick with python 3.6.x.
choco install -y python -Version 3.6.6

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# install the example dependencies.
python -m pip -q install -r requirements.txt

# run the example.
python main.py
