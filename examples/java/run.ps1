# install dependencies.
choco install -y jdk8 gradle

# update $env:PATH with the recently installed Chocolatey packages.
Import-Module C:\ProgramData\chocolatey\helpers\chocolateyInstaller.psm1
Update-SessionEnvironment

# add our Example CA certificate to the default java trust store.
@(
    'C:\Program Files\Java\jre*\lib\security\cacerts'
    'C:\Program Files\Java\jdk*\jre\lib\security\cacerts'
) | ForEach-Object {Get-ChildItem $_} | ForEach-Object {
    $keyStore = $_
    $alias = 'Example CA'
    $keytool = Resolve-Path "$keyStore\..\..\..\bin\keytool.exe"
    $keytoolOutput = &$keytool `
        -noprompt `
        -list `
        -storepass changeit `
        -keystore "$keyStore" `
        -alias "$alias"
    if ($keytoolOutput -match 'keytool error: java.lang.Exception: Alias .+ does not exist') {
        Write-Host "Adding $alias to the java $keyStore keystore..."
        # NB we use Start-Process because keytool writes to stderr... and that
        #    triggers PowerShell to fail, so we work around this by redirecting
        #    stdout and stderr to a temporary file.
        # NB keytool exit code is always 1, so we cannot rely on that.
        Start-Process `
            -FilePath $keytool `
            -ArgumentList `
                '-noprompt',
                '-import',
                '-trustcacerts',
                '-storepass changeit',
                "-keystore `"$keyStore`"",
                "-alias `"$alias`"",
                '-file c:\vagrant\tmp\ca\example-ca-crt.der' `
            -RedirectStandardOutput "$env:TEMP\keytool-stdout.txt" `
            -RedirectStandardError "$env:TEMP\keytool-stderr.txt" `
            -NoNewWindow `
            -Wait
        $keytoolOutput = Get-Content -Raw "$env:TEMP\keytool-stdout.txt","$env:TEMP\keytool-stderr.txt"
        if ($keytoolOutput -notmatch 'Certificate was added to keystore') {
            Write-Host $keytoolOutput
            throw "failed to import Example CA"
        }
    } elseif ($LASTEXITCODE) {
        Write-Host $keytoolOutput
        throw "failed to list Example CA with exit code $LASTEXITCODE"
    }
}

# build into a fat jar.
# NB gradle build would also work, but having a fat jar is nicier for distribution.
gradle shadowJar

# run the example.
# NB gradle run would also work, but this shows how a user would use the fat jar.
# NB for using the integrated authentication we must have sqljdbc_auth.dll in the
#    current directory, %PATH%, or inside one of the directories defined in the
#    java.library.path java property (as done here; it points to the drivers
#    installed by the sqljdbc chocolatey package).
$javaLibraryPath = (Resolve-Path 'C:\Program Files\Microsoft JDBC DRIVER*\sqljdbc*\enu\auth\x64').Path
java "-Djava.library.path=$javaLibraryPath" -jar build/libs/example-1.0.0-all.jar
