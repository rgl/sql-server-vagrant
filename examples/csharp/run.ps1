if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://dotnet.microsoft.com/download/dotnet/6.0
    # see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.11/6.0.11.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/08ada4db-1e64-4829-b36d-5beb71f67bff/b77050cf7e0c71d3b95418651db1a9b8/dotnet-sdk-6.0.403-win-x64.exe'
    $archiveHash = 'cc30833cee9cf74cb3c0ac16eab5a96345daecbf73be9d8de1e9ec221cb270a319374fc8b35f28432379f35b39b6e3306e06ec93696be7d4a6c69afc3d676884'
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
}

# show information about dotnet.
dotnet --info

# restore the packages.
dotnet restore

# build and run.
dotnet --diagnostics build --configuration Release
dotnet --diagnostics run --configuration Release
