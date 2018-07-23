# define a function for easying the execution of bash scripts.
$bashPath = 'C:\tools\msys64\usr\bin\bash.exe'
function Bash($script) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        # we also redirect the stderr to stdout because PowerShell
        # oddly interleaves them.
        # see https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin
        Write-Output 'exec 2>&1;set -eu;export PATH="/usr/bin:$PATH"' $script | &$bashPath
        if ($LASTEXITCODE) {
            throw "bash execution failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

# create a testing CA and a certificate for the current machine.
$ca_file_name = 'example-ca'
$ca_common_name = 'Example CA'
$domain = $env:COMPUTERNAME
$ip = (Get-NetAdapter -Name 'Ethernet 2' | Get-NetIPAddress -AddressFamily IPv4).IPAddress

Bash @"
mkdir -p /c/vagrant/tmp/ca
cd /c/vagrant/tmp/ca

# see https://www.openssl.org/docs/man1.0.2/apps/x509v3_config.html

# create CA certificate.
if [ ! -f $ca_file_name-crt.pem ]; then
    openssl genrsa \
        -out $ca_file_name-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $ca_file_name-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$ca_common_name" \
        -key $ca_file_name-key.pem \
        -out $ca_file_name-csr.pem
    openssl x509 -req -sha256 \
        -signkey $ca_file_name-key.pem \
        -extensions a \
        -extfile <(echo "[a]
            basicConstraints=critical,CA:TRUE,pathlen:0
            keyUsage=critical,digitalSignature,keyCertSign,cRLSign
            ") \
        -days 90 \
        -in  $ca_file_name-csr.pem \
        -out $ca_file_name-crt.pem
    openssl x509 \
        -in $ca_file_name-crt.pem \
        -outform der \
        -out $ca_file_name-crt.der
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $ca_file_name-crt.pem
fi

# create a server certificate that is usable by SQL Server.
if [ ! -f $domain-crt.pem ]; then
    openssl genrsa \
        -out $domain-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $domain-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$domain" \
        -key $domain-key.pem \
        -out $domain-csr.pem
    openssl x509 -req -sha256 \
        -CA $ca_file_name-crt.pem \
        -CAkey $ca_file_name-key.pem \
        -CAcreateserial \
        -extensions a \
        -extfile <(echo "[a]
            subjectAltName=DNS:$domain,IP:$ip
            extendedKeyUsage=critical,serverAuth
            ") \
        -days 90 \
        -in  $domain-csr.pem \
        -out $domain-crt.pem
    openssl pkcs12 -export \
        -keyex \
        -inkey $domain-key.pem \
        -in $domain-crt.pem \
        -certfile $domain-crt.pem \
        -passout pass: \
        -out $domain-key.p12
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $domain-crt.pem
    #openssl pkcs12 -info -nodes -passin pass: -in $domain-key.p12
fi
"@

Write-Host "Importing $ca_file_name CA..."
Import-Certificate `
    -FilePath "c:\vagrant\tmp\ca\$ca_file_name-crt.der" `
    -CertStoreLocation Cert:\LocalMachine\Root `
    | Out-Null

Write-Host "Importing $domain p12..."
Import-PfxCertificate `
    -FilePath "c:\vagrant\tmp\ca\$domain-key.p12" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $null `
    -Exportable `
    | Out-Null

Write-Host "Configuring SQL Server to allow encrypted connections at $domain..."
$certificate = Get-ChildItem -DnsName $domain Cert:\LocalMachine\My
$superSocketNetLibPath = Resolve-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL*.SQLEXPRESS\MSSQLServer\SuperSocketNetLib'
Set-ItemProperty `
    -Path $superSocketNetLibPath `
    -Name Certificate `
    -Value $certificate.Thumbprint
Set-ItemProperty `
    -Path $superSocketNetLibPath `
    -Name ForceEncryption `
    -Value 0 # NB set to 1 to force all connections to be encrypted.

Write-Host "Granting SQL Server Read permissions to the $domain private key..."
# NB this originally came from http://stackoverflow.com/questions/17185429/how-to-grant-permission-to-private-key-from-powershell/22146915#22146915
function Get-PrivateKeyContainerPath() {
    param(
        [Parameter(Mandatory=$true)][string][ValidateNotNullOrEmpty()]$name,
        [Parameter(Mandatory=$true)][boolean]$isCng
    )
    if ($isCng) {
        $searchDirectories = @('Microsoft\Crypto\Keys', 'Microsoft\Crypto\SystemKeys')
    } else {
        $searchDirectories = @('Microsoft\Crypto\RSA\MachineKeys', 'Microsoft\Crypto\RSA\S-1-5-18', 'Microsoft\Crypto\RSA\S-1-5-19', 'Crypto\DSS\S-1-5-20')
    }
    $commonApplicationDataDirectory = [Environment]::GetFolderPath('CommonApplicationData')
    foreach ($searchDirectory in $searchDirectories) {
        $privateKeyFile = Get-ChildItem -Path "$commonApplicationDataDirectory\$searchDirectory" -Filter $name -Recurse
        if ($privateKeyFile) {
            return $privateKeyFile.FullName
        }
    }
    throw "cannot find private key file path for the $name key container"
}
Add-Type -Path '.\Security.Cryptography.dll' # from https://clrsecurity.codeplex.com/
function Grant-PrivateKeyReadPermissions($certificate, $accountName) {
    if ([Security.Cryptography.X509Certificates.X509CertificateExtensionMethods]::HasCngKey($certificate)) {
        $privateKey = [Security.Cryptography.X509Certificates.X509Certificate2ExtensionMethods]::GetCngPrivateKey($certificate)
        $keyContainerName = $privateKey.UniqueName
        $privateKeyPath = Get-PrivateKeyContainerPath $keyContainerName $true
    } elseif ($certificate.PrivateKey) {
        $privateKey = $certificate.PrivateKey        
        $keyContainerName = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName      
        $privateKeyPath = Get-PrivateKeyContainerPath $keyContainerName $false
    } else {
        throw 'certificate does not have a private key, or that key is inaccessible, therefore permission cannot be granted'
    }
    $acl = Get-Acl -Path $privateKeyPath
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule @($accountName, 'Read', 'Allow')))
    Set-Acl $privateKeyPath $acl
}
Grant-PrivateKeyReadPermissions $certificate 'MSSQL$SQLEXPRESS'
Restart-Service 'MSSQL$SQLEXPRESS' -Force
