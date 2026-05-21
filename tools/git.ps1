# ============================================================
#  git-Wrapper fuer PowerShell
#  Ruft git im permanent laufenden 'tools'-Container auf.
#  Voraussetzung:  docker compose up -d
# ============================================================

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root      = (Resolve-Path (Join-Path $scriptDir '..')).Path.TrimEnd('\')
$cwd       = (Get-Location).Path.TrimEnd('\')

if ($cwd -ieq $root) {
    $workdir = '/work'
}
elseif ($cwd.ToLower().StartsWith($root.ToLower() + '\')) {
    $rel     = $cwd.Substring($root.Length + 1).Replace('\', '/')
    $workdir = "/work/$rel"
}
else {
    Write-Host "[git-wrapper] Du musst im Projektverzeichnis (oder darunter) sein:" -ForegroundColor Red
    Write-Host "  $root" -ForegroundColor Red
    exit 1
}

docker compose -f (Join-Path $root 'docker-compose.yml') exec -T -w $workdir tools git @args
exit $LASTEXITCODE
