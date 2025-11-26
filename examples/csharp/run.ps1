if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe) -or !(dotnet --list-sdks)) {
    # see https://dotnet.microsoft.com/en-us/download/dotnet/10.0
    # see https://github.com/dotnet/core/blob/main/release-notes/10.0/10.0.0/10.0.0.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.100/dotnet-sdk-10.0.100-win-x64.exe'
    $archiveHash = 'e9920ce4b9b2fa3ce63a35f288080bb8d2b7f5bfbf2d51588276f81eddc8858254760f172aa1d0a7211a98378816c6e8bb17b59f4844db8456988ad10a557ca9'
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
