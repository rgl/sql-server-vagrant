# see https://community.chocolatey.org/packages/chocolatey
$env:chocolateyVersion = '2.4.3'

Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
