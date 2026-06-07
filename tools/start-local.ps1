param(
    [ValidateSet("7.4", "8.5")]
    [string]$Php = "8.5",
    [ValidateSet("caddy", "builtin")]
    [string]$Server = "caddy",
    [int]$Port = 8088
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtime = Join-Path $root "local-runtime"
$mariaDir = Join-Path $runtime "mariadb"
$mariaIni = Join-Path $mariaDir "my.ini"
$mariaPid = Join-Path $runtime "mariadb.pid"
$phpPid = Join-Path $runtime "php-server.pid"
$phpCgiPid = Join-Path $runtime "php-cgi.pid"
$caddyPid = Join-Path $runtime "caddy.pid"
$phpDir = Join-Path $runtime ($(if ($Php -eq "7.4") { "php74" } else { "php" }))
$phpExe = Join-Path $phpDir "php.exe"
$phpCgiExe = Join-Path $phpDir "php-cgi.exe"
$caddyExe = Join-Path $runtime "caddy\caddy.exe"
$caddyConfig = Join-Path $runtime "Caddyfile"
$router = Join-Path $root "tools\wp-router.php"
$fastCgiHost = "127.0.0.1"
$fastCgiPort = 9000

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

function Stop-ProcessFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    $processId = Get-Content $Path -ErrorAction SilentlyContinue
    if ($processId) {
        $process = Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $process.Id -Force
        }
    }

    Remove-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
}

function Stop-LocalRuntimeListener {
    param([int]$PortNumber)

    $listeners = netstat -ano | Select-String ":$PortNumber" | Where-Object { $_ -match "LISTENING" }
    foreach ($listener in $listeners) {
        if ($listener.Line -notmatch "\s+(\d+)\s*$") {
            continue
        }

        $listenerProcessId = [int]$Matches[1]
        $process = Get-Process -Id $listenerProcessId -ErrorAction SilentlyContinue
        if (-not $process -or -not $process.Path) {
            continue
        }

        $isLocalRuntime = $process.Path.StartsWith($runtime, [System.StringComparison]::OrdinalIgnoreCase)
        $isProjectProcess = $process.Path.StartsWith($root.Path, [System.StringComparison]::OrdinalIgnoreCase)
        if ($isLocalRuntime -or $isProjectProcess) {
            Stop-Process -Id $listenerProcessId -Force
        }
    }
}

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$PortNumber
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $task = $client.ConnectAsync($HostName, $PortNumber)
        if (-not $task.Wait(1000)) {
            return $false
        }
        return $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
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

Stop-ProcessFile $phpPid
Stop-ProcessFile $phpCgiPid
Stop-ProcessFile $caddyPid
Stop-LocalRuntimeListener $Port
Stop-LocalRuntimeListener $fastCgiPort

if ($Server -eq "builtin") {
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
} else {
    if (-not (Test-Path $phpCgiExe)) {
        throw "PHP CGI runtime is missing: $phpCgiExe"
    }
    if (-not (Test-Path $caddyExe)) {
        throw "Caddy runtime is missing: $caddyExe"
    }

    $env:PATH = $phpDir + ";" + $env:PATH
    $phpCgiOut = Join-Path $runtime "php-cgi.out.log"
    $phpCgiErr = Join-Path $runtime "php-cgi.err.log"
    Remove-Item -LiteralPath $phpCgiOut, $phpCgiErr -Force -ErrorAction SilentlyContinue
    $phpCgiProcess = Start-Process `
        -FilePath $phpCgiExe `
        -ArgumentList "-c `"$phpDir\php.ini`" -b ${fastCgiHost}:$fastCgiPort" `
        -WorkingDirectory $root `
        -WindowStyle Hidden `
        -RedirectStandardOutput $phpCgiOut `
        -RedirectStandardError $phpCgiErr `
        -PassThru
    Set-Content -Path $phpCgiPid -Value $phpCgiProcess.Id -Encoding ASCII

    $fastCgiReady = $false
    for ($i = 0; $i -lt 30; $i++) {
        if (Test-TcpPort $fastCgiHost $fastCgiPort) {
            $fastCgiReady = $true
            break
        }
        Start-Sleep -Seconds 1
    }

    if (-not $fastCgiReady) {
        throw "PHP FastCGI did not become ready on ${fastCgiHost}:$fastCgiPort"
    }

    $rootForCaddy = ($root.Path -replace '\\', '/')
    $caddyText = @"
{
    auto_https off
    admin off
}

http://127.0.0.1:$Port {
    root * $rootForCaddy
    encode zstd gzip
    php_fastcgi ${fastCgiHost}:$fastCgiPort
    file_server
}
"@
    Set-Content -Path $caddyConfig -Value $caddyText -Encoding UTF8

    $caddyOut = Join-Path $runtime "caddy.out.log"
    $caddyErr = Join-Path $runtime "caddy.err.log"
    Remove-Item -LiteralPath $caddyOut, $caddyErr -Force -ErrorAction SilentlyContinue
    $caddyProcess = Start-Process `
        -FilePath $caddyExe `
        -ArgumentList "run --config `"$caddyConfig`" --adapter caddyfile" `
        -WorkingDirectory $root `
        -WindowStyle Hidden `
        -RedirectStandardOutput $caddyOut `
        -RedirectStandardError $caddyErr `
        -PassThru
    Set-Content -Path $caddyPid -Value $caddyProcess.Id -Encoding ASCII
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
Write-Output "Web server: $Server"
