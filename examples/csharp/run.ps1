# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# see https://github.com/dotnet/cli/releases/tag/v1.0.0-rc4-004771
# see https://blogs.msdn.microsoft.com/dotnet/2017/02/07/announcing-net-core-tools-updates-in-vs-2017-rc/
$cliVersion = '1.0.0-rc4-004771'
$cliHome = "c:\ProgramData\dotnet-sdk-$cliVersion"
$archiveName = "dotnet-dev-win-x64.$cliVersion.zip"
$archivePath = "$env:TEMP\$archiveName"
Write-Host "Downloading $archiveName..."
Invoke-WebRequest "https://download.microsoft.com/download/B/4/6/B4678511-01F4-4F97-902B-0E58A985932A/$archiveName" -UseBasicParsing -OutFile $archivePath
Expand-Archive $archivePath -DestinationPath $cliHome
Remove-Item $archivePath

# add dotnet to the Machine PATH.
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$cliHome",
    'Machine')

# add dotnet to the current PATH.
$env:PATH += ";$cliHome"

# show information about dotnet.
dotnet --info

# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics run --configuration Release
