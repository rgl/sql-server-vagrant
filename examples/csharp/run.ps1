if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://github.com/dotnet/core/blob/master/release-notes/3.1/3.1.5/3.1.301-download.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/4e88f517-196e-4b17-a40c-2692c689661d/eed3f5fca28262f764d8b650585a7278/dotnet-sdk-3.1.301-win-x64.exe'
    $archiveHash = 'd4c564fb970f8f21ae7c1ae3185eb1f048d2ff79755198c25cfe461049c3a34de7392c8f4c66da2591b086ea69fb4d9caf830346ed98619743a201d05148ca16'
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
        throw "Failed to install dotnetcore-sdk with Exit Code $LASTEXITCODE"
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
