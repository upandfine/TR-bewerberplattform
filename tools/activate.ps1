# ============================================================
#  Tools fuer die aktuelle PowerShell-Sitzung verfuegbar machen.
#
#  Aufruf vom Projekt-Root aus (gepunktet, damit das Script die
#  aktuelle Sitzung veraendern darf):
#      . .\tools\activate.ps1
#
#  Danach funktionieren "git" und "curl" wie nativ installiert,
#  solange das Fenster offen bleibt. Kein System-PATH wird
#  veraendert.
# ============================================================

$toolsDir = $PSScriptRoot
$env:Path = "$toolsDir;$env:Path"

# In PowerShell ist "curl" standardmaessig ein Alias auf
# Invoke-WebRequest. Den Alias entfernen, damit "curl" unseren
# Wrapper trifft. Gleiches gilt fuer "wget".
foreach ($name in @('curl', 'wget')) {
    if (Test-Path "Alias:$name") {
        Remove-Item "Alias:$name" -Force
    }
}

Write-Host "Tools (git, curl) sind in dieser Sitzung verfuegbar." -ForegroundColor Green
Write-Host 'Hinweis: erst einmalig "docker compose up -d" ausfuehren.'
