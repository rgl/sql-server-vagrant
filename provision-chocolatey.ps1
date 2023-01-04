# see https://community.chocolatey.org/packages/chocolatey
$env:chocolateyVersion = '1.2.1'

Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
