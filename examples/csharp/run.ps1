# opt-out from dotnet telemetry.
[Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

# install the dotnet sdk.
# see https://github.com/dotnet/cli/releases/tag/v1.0.0-preview4-004233
# see https://github.com/dotnet/core/blob/master/release-notes/preview4-download.md
# see https://docs.microsoft.com/en-us/dotnet/articles/core/preview3/tools/
$cliVersion = '1.0.0-preview4-004233'
$cliHome = "c:\ProgramData\dotnet-sdk-$cliVersion"
$archiveName = "dotnet-dev-win-x64.$cliVersion.zip"
$archivePath = "$env:TEMP\$archiveName"
Invoke-WebRequest "https://download.microsoft.com/download/7/E/8/7E8BD9BD-2892-4848-BA01-76493DECC138/$archiveName" -UseBasicParsing -OutFile $archivePath
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
dotnet --verbose build --configuration Release
dotnet --verbose run --configuration Release
