if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe) -or !(dotnet --list-sdks)) {
    # see https://dotnet.microsoft.com/en-us/download/dotnet/6.0
    # see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.20/6.0.20.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/6a7d9254-d184-41a1-91fc-00ed876297a9/9db88f1a5fe2375b8c389d7087db132e/dotnet-sdk-6.0.412-win-x64.exe'
    $archiveHash = '7465163a2681b37bf164c6a257fc72e3865c98ed56a6a1a378302c91a0482a9c3405ca5adae46d3cd93859751b8724a0f67aa942e8a982e52a65306556c2a3ab'
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

# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics run --configuration Release
