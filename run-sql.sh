#!/usr/bin/env bash
# ============================================================
#  Führt eine SQL-Datei gegen die laufende MariaDB aus.
#
#  Verwendung:
#      ./run-sql.sh                       (nimmt das Beispiel-Skript)
#      ./run-sql.sh sql/scripts/meins.sql
#
#  Voraussetzung: die Umgebung läuft  ->  docker compose up -d
# ============================================================
set -euo pipefail

# Standard-Datei, falls keine angegeben wurde
SQL_FILE="${1:-sql/scripts/beispiel.sql}"

if [ ! -f "$SQL_FILE" ]; then
  echo "Datei nicht gefunden: $SQL_FILE"
  exit 1
fi

# Prüfen, ob der DB-Container läuft
if ! docker compose ps --status running db | grep -q db; then
  echo "Der Datenbank-Container läuft nicht. Bitte zuerst:  docker compose up -d"
  exit 1
fi

echo ">> Führe '$SQL_FILE' auf der Datenbank aus ..."

# Das Passwort wird NICHT übergeben, sondern aus der Container-
# eigenen Umgebung gelesen -> keine Klartext-Anzeige.
docker compose exec -T db sh -c \
  'exec mariadb -u root -p"$MARIADB_ROOT_PASSWORD" "$MARIADB_DATABASE"' \
  < "$SQL_FILE"

echo ">> Fertig."
