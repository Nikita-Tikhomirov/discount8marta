$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$runtime = Join-Path $root "local-runtime"
$pidFiles = @(
    (Join-Path $runtime "php-server.pid"),
    (Join-Path $runtime "mariadb.pid")
)

foreach ($pidFile in $pidFiles) {
    if (-not (Test-Path $pidFile)) {
        continue
    }

    $processId = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($processId) {
        $process = Get-Process -Id ([int]$processId) -ErrorAction SilentlyContinue
        if ($process) {
            Stop-Process -Id $process.Id -Force
        }
    }

    Remove-Item -LiteralPath $pidFile -Force
}

Write-Output "Local site processes stopped."
