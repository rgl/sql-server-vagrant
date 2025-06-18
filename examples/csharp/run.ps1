if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe) -or !(dotnet --list-sdks)) {
    # see https://dotnet.microsoft.com/en-us/download/dotnet/8.0
    # see https://github.com/dotnet/core/blob/main/release-notes/8.0/8.0.16/8.0.16.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/8.0.410/dotnet-sdk-8.0.410-win-x64.exe'
    $archiveHash = 'ff5c515d0b269f72f986499dc00cf74e88d10daee4e37a5d270b32fe031d0f272964093c301ec37e29cd252798cf77721b24cd64707c38f0f714dcb13e9db432'
    $archiveName = Split-Path -Leaf $archiveUrl
    $archivePath = "$env:TEMP\$archiveName"
    Write-Host "Downloading $archiveName..."
    (New-Object Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    $archiveActualHash = (Get-FileHash $archivePath -Algorithm SHA512).Hash
    if ($archiveHash -ne $archiveActualHash) {
        throw "$archiveName downloaded from $archiveUrl to $archivePath has $archiveActualHash hash witch does not match the expected $archiveHash"
    }
    Write-Host "Installing $archiveName..."
    &$archivePath /install /quiet /norestart | Out-String -Stream
    if ($LASTEXITCODE) {
        throw "Failed to install dotnet-sdk with Exit Code $LASTEXITCODE"
    }
    Remove-Item $archivePath

    # reload PATH.
    $env:PATH = "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$([Environment]::GetEnvironmentVariable('PATH', 'User'))"

    # add the nuget.org source.
    # see https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-nuget-add-source
    Write-Host "Adding the nuget nuget.org source..."
    dotnet nuget add source --name nuget.org https://api.nuget.org/v3/index.json
    dotnet nuget list source
}

# show information about dotnet.
dotnet --info
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# restore the packages.
dotnet restore
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}

# build and run.
dotnet --diagnostics build --configuration Release
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
dotnet --diagnostics run --configuration Release
if ($LASTEXITCODE) {
    throw "failed with exit code $LASTEXITCODE"
}
