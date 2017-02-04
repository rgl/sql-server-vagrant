# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# see https://blogs.msdn.microsoft.com/dotnet/2017/01/30/announcing-net-core-net-native-and-nuget-updates-in-vs-2017-rc/
$cliVersion = '1.0.0-rc3-004530'
$cliHome = "c:\ProgramData\dotnet-sdk-$cliVersion"
$archiveName = "dotnet-dev-win-x64.$cliVersion.zip"
$archivePath = "$env:TEMP\$archiveName"
Invoke-WebRequest "https://download.microsoft.com/download/9/7/1/97197CC0-EC7D-45CA-979C-2ABF9B5508A3/$archiveName" -UseBasicParsing -OutFile $archivePath
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
