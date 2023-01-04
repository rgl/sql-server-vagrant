if (!(Get-Command -ErrorAction SilentlyContinue dotnet.exe)) {
    # see https://dotnet.microsoft.com/en-us/download/dotnet/6.0
    # see https://github.com/dotnet/core/blob/main/release-notes/6.0/6.0.12/6.0.12.md

    # opt-out from dotnet telemetry.
    [Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', 'Machine')
    $env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

    # install the dotnet sdk.
    $archiveUrl = 'https://download.visualstudio.microsoft.com/download/pr/0a672516-37fb-40de-8bef-725975e0b137/a632cde8d629f9ba9c12196f7e7660db/dotnet-sdk-6.0.404-win-x64.exe'
    $archiveHash = '4e4f9f2ad0c74aa69f488e50c8722caabb55bf8cdeca7bd265713dddf2870d2ba0978798b55d44b0f5ba2ecdd979a6d5faae79cf9645270bd5fd2a21d1fab35d'
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
