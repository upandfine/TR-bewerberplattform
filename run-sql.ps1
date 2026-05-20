# ============================================================
#  Führt eine SQL-Datei gegen die laufende MariaDB aus.
#  PowerShell-Variante von run-sql.sh - für Windows-Teilnehmende.
#
#  Verwendung:
#      .\run-sql.ps1                       (nimmt das Beispiel-Skript)
#      .\run-sql.ps1 sql\scripts\meins.sql
#
#  Voraussetzung: die Umgebung läuft  ->  docker compose up -d
#
#  Funktioniert in Windows PowerShell 5.1 und PowerShell 7+,
#  weil die Datei per "docker compose cp" in den Container
#  übertragen wird (kein PowerShell-Pipe-Encoding).
# ============================================================

param(
    [string]$File = "sql/scripts/beispiel.sql"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $File)) {
    Write-Host "Datei nicht gefunden: $File" -ForegroundColor Red
    exit 1
}

# Prüfen, ob der DB-Container läuft
$running = docker compose ps --status running db 2>$null
if (-not ($running | Select-String -SimpleMatch "db")) {
    Write-Host "Der Datenbank-Container läuft nicht. Bitte zuerst:  docker compose up -d" -ForegroundColor Red
    exit 1
}

Write-Host ">> Übertrage '$File' in den DB-Container ..."
docker compose cp $File db:/tmp/run-sql.sql | Out-Null

Write-Host ">> Führe '$File' auf der Datenbank aus ..."
docker compose exec -T db sh -c 'exec mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE" < /tmp/run-sql.sql'

# Aufräumen im Container
docker compose exec -T db rm -f /tmp/run-sql.sql | Out-Null

Write-Host ">> Fertig." -ForegroundColor Green
