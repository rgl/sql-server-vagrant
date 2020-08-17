# install go.
choco install -y golang --version 1.15

# setup the current process environment.
$env:GOROOT = 'C:\Go'
$env:PATH += ";$env:GOROOT\bin"

# setup the Machine environment.
[Environment]::SetEnvironmentVariable('GOROOT', $env:GOROOT, 'Machine')
[Environment]::SetEnvironmentVariable(
    'PATH',
    "$([Environment]::GetEnvironmentVariable('PATH', 'Machine'));$env:GOROOT\bin",
    'Machine')

Write-Host '# go env'
go env

Write-Host '# build and run'
$p = Start-Process go 'build','-v' `
    -RedirectStandardOutput build-stdout.txt `
    -RedirectStandardError build-stderr.txt `
    -Wait `
    -PassThru
Write-Output (Get-Content build-stdout.txt,build-stderr.txt)
Remove-Item build-stdout.txt,build-stderr.txt
if ($p.ExitCode) {
    throw "Failed to compile"
}
.\go.exe
