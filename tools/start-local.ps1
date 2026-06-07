param(
    [ValidateSet("7.4", "8.5")]
    [string]$Php = "7.4",
    [int]$Port = 8088
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtime = Join-Path $root "local-runtime"
$mariaDir = Join-Path $runtime "mariadb"
$mariaIni = Join-Path $mariaDir "my.ini"
$mariaPid = Join-Path $runtime "mariadb.pid"
$phpPid = Join-Path $runtime "php-server.pid"
$phpDir = Join-Path $runtime ($(if ($Php -eq "7.4") { "php74" } else { "php" }))
$phpExe = Join-Path $phpDir "php.exe"
$router = Join-Path $root "tools\wp-router.php"

function Test-ProcessId {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    $processId = Get-Content $Path -ErrorAction SilentlyContinue
    if (-not $processId) {
        return $false
    }

    $process = Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue
    if ($process) {
        return $true
    }

    Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    return $false
}

if (-not (Test-Path $phpExe)) {
    throw "PHP runtime is missing: $phpExe"
}

if (-not (Test-Path $mariaIni)) {
    throw "MariaDB config is missing: $mariaIni"
}

if (-not (Test-ProcessId $mariaPid)) {
    $mariadbd = Join-Path $mariaDir "bin\mariadbd.exe"
    $mariaProcess = Start-Process `
        -FilePath $mariadbd `
        -ArgumentList "--defaults-file=`"$mariaIni`" --console" `
        -WorkingDirectory $mariaDir `
        -WindowStyle Hidden `
        -PassThru
    Set-Content -Path $mariaPid -Value $mariaProcess.Id -Encoding ASCII
}

$mariaAdmin = Join-Path $mariaDir "bin\mariadb-admin.exe"
$databaseReady = $false
for ($i = 0; $i -lt 30; $i++) {
    & $mariaAdmin --defaults-file="$mariaIni" ping *> $null
    if ($LASTEXITCODE -eq 0) {
        $databaseReady = $true
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $databaseReady) {
    throw "MariaDB did not become ready on 127.0.0.1:3307"
}

if (-not (Test-ProcessId $phpPid)) {
    $env:PATH = $phpDir + ";" + $env:PATH
    $phpOut = Join-Path $runtime "php-server.out.log"
    $phpErr = Join-Path $runtime "php-server.err.log"
    Remove-Item -LiteralPath $phpOut, $phpErr -Force -ErrorAction SilentlyContinue
    $phpProcess = Start-Process `
        -FilePath $phpExe `
        -ArgumentList "-c `"$phpDir\php.ini`" -S 127.0.0.1:$Port -t `"$root`" `"$router`"" `
        -WorkingDirectory $root `
        -WindowStyle Hidden `
        -RedirectStandardOutput $phpOut `
        -RedirectStandardError $phpErr `
        -PassThru
    Set-Content -Path $phpPid -Value $phpProcess.Id -Encoding ASCII
}

$url = "http://127.0.0.1:$Port/"
$siteReady = $false
$lastError = ""
for ($i = 0; $i -lt 30; $i++) {
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 5 | Out-Null
        $siteReady = $true
        break
    } catch {
        $lastError = $_.Exception.Message
        Start-Sleep -Seconds 1
    }
}

if (-not $siteReady) {
    throw "WordPress did not respond at $url. Last error: $lastError"
}

Write-Output "Local site is running: $url"
Write-Output "PHP runtime: $Php"
