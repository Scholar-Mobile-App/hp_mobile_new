$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $projectRoot 'android'
$keystorePath = Join-Path $androidDir 'app\upload-keystore.jks'
$propertiesPath = Join-Path $androidDir 'key.properties'
$certificatePath = Join-Path $androidDir 'upload_certificate.pem'
$recoveryPath = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'g2g-upload-key-recovery.txt'
$keytoolPath = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
$alias = 'upload'

foreach ($path in @($keystorePath, $propertiesPath, $certificatePath, $recoveryPath)) {
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to overwrite existing signing file: $path"
    }
}

if (-not (Test-Path -LiteralPath $keytoolPath)) {
    throw "keytool was not found at: $keytoolPath"
}

$randomBytes = New-Object byte[] 32
$randomGenerator = [Security.Cryptography.RandomNumberGenerator]::Create()
$randomGenerator.GetBytes($randomBytes)
$randomGenerator.Dispose()
$password = [Convert]::ToBase64String($randomBytes).Replace('+', 'A').Replace('/', 'B').TrimEnd('=')

& $keytoolPath `
    -genkeypair `
    -v `
    -keystore $keystorePath `
    -storetype JKS `
    -storepass $password `
    -keypass $password `
    -alias $alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname 'CN=G2G Upload Key, OU=Mobile, O=TRIZ, L=Surat, ST=Gujarat, C=IN'

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed to create the upload keystore."
}

$properties = @(
    "storePassword=$password"
    "keyPassword=$password"
    "keyAlias=$alias"
    "storeFile=upload-keystore.jks"
)
[IO.File]::WriteAllLines($propertiesPath, $properties)

& $keytoolPath `
    -export `
    -rfc `
    -keystore $keystorePath `
    -storepass $password `
    -alias $alias `
    -file $certificatePath

if ($LASTEXITCODE -ne 0) {
    throw "keytool failed to export the upload certificate."
}

$recovery = @(
    'G2G Google Play upload key recovery details'
    "Created: $([DateTime]::Now.ToString('u'))"
    "Keystore: $keystorePath"
    "Alias: $alias"
    "Store password: $password"
    "Key password: $password"
    ''
    'Keep this file and upload-keystore.jks in secure, separate backups.'
)
[IO.File]::WriteAllLines($recoveryPath, $recovery)

Write-Output "Keystore: $keystorePath"
Write-Output "Certificate: $certificatePath"
Write-Output "Properties: $propertiesPath"
Write-Output "Recovery details: $recoveryPath"
