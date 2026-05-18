# Lernumgebung Fachinformatiker

Eine einfache Docker-Umgebung mit Datenbank und drei Webservern
(PHP, Python, Node.js) sowie phpMyAdmin. Gedacht für Teilnehmende
einer Umschulung zum Fachinformatiker – mit sinnvollen Standardwerten,
damit es ohne lange Einrichtung läuft.

---

## 1. Was ist enthalten?

| Container    | Technologie        | Adresse im Browser              |
|--------------|--------------------|---------------------------------|
| `db`         | MariaDB 11         | (nur intern, Port 3306)         |
| `php`        | PHP 8.4 + Apache   | http://localhost:8080           |
| `python`     | Python 3.12 (Flask)| http://localhost:8001           |
| `node`       | Node.js 22 (Express)| http://localhost:3000          |
| `phpmyadmin` | phpMyAdmin         | http://localhost:8081           |

Die Ports lassen sich in der Datei `.env` ändern, falls einer
auf deinem Rechner schon belegt ist.

---

## 2. Voraussetzungen

- **Docker Desktop** installiert und gestartet
- Ein Terminal (macOS/Linux: Terminal, Windows: PowerShell)

Prüfen, ob Docker bereit ist:

```bash
docker --version
docker compose version
```

---

## 3. Schnellstart

```bash
# 1. Zugangsdaten anlegen (einmalig)
cp .env.example .env

# 2. Alle Container bauen und starten
docker compose up -d --build

# 3. Status prüfen
docker compose ps
```

Danach im Browser öffnen:

- PHP:        http://localhost:8080
- Python:     http://localhost:8001
- Node.js:    http://localhost:3000
- phpMyAdmin: http://localhost:8081

Jede Demo-Seite zeigt grün an, ob die Datenbank-Verbindung steht.

> Hinweis: Eine fertige `.env` liegt bereits bei, damit es sofort
> läuft. Für eigene Passwörter einfach die Werte in `.env` ändern
> und danach `docker compose up -d` erneut ausführen.

---

## 4. Zugangsdaten (`.env`)

Alle Passwörter stehen **zentral** in der Datei `.env`.
Sie wird **nicht** in Git eingecheckt (siehe `.gitignore`).

| Variable                 | Bedeutung                          | Standard           |
|--------------------------|------------------------------------|--------------------|
| `MARIADB_ROOT_PASSWORD`  | Passwort des DB-Admins (`root`)    | `rootpass`         |
| `MARIADB_DATABASE`       | Name der Datenbank                 | `bewerberplattform`|
| `MARIADB_USER`           | Normaler Arbeits-Benutzer          | `app`              |
| `MARIADB_PASSWORD`       | Passwort des Arbeits-Benutzers     | `apppass`          |

**Anmeldung in phpMyAdmin:**
Benutzer `root` mit `MARIADB_ROOT_PASSWORD`
(oder Benutzer `app` mit `MARIADB_PASSWORD`).

---

## 5. SQL / DDL-Skripte ausführen

Es gibt zwei Wege – beide nutzen den Ordner `sql/`.

```
sql/
├── init/      -> läuft AUTOMATISCH beim ersten Start
└── scripts/   -> wird MANUELL ausgeführt (jederzeit)
```

### Weg A – Automatisch beim ersten Start

Jede `.sql`-Datei im Ordner `sql/init/` wird beim **allerersten**
Start der Datenbank automatisch ausgeführt (Reihenfolge nach
Dateiname, z. B. `01-…`, `02-…`).

Die mitgelieferte Datei `sql/init/01-schema.sql` legt eine
Beispiel-Tabelle `bewerber` mit zwei Datensätzen an.

> Das läuft nur, solange noch keine Daten existieren.
> Zum erneuten Ausführen siehe Abschnitt 7 (Datenbank zurücksetzen).

### Weg B – Eigenes Skript jederzeit ausführen

Für den laufenden Betrieb gibt es das Helfer-Skript `run-sql.sh`:

```bash
# Beispiel-Skript ausführen
./run-sql.sh

# Eigenes Skript ausführen
./run-sql.sh sql/scripts/meins.sql
```

**Empfohlener Ablauf für Teilnehmende:**

1. Neue Datei in `sql/scripts/` anlegen, z. B. `meins.sql`
2. SQL/DDL hineinschreiben (`CREATE TABLE`, `INSERT`, …)
3. Ausführen: `./run-sql.sh sql/scripts/meins.sql`
4. Ergebnis in phpMyAdmin (http://localhost:8081) kontrollieren

> Windows-Hinweis: Wenn `./run-sql.sh` nicht startet, in der
> PowerShell mit `bash run-sql.sh sql/scripts/meins.sql` ausführen
> (Git Bash / WSL vorausgesetzt).

---

## 6. Eigenen Code schreiben

Der Code liegt direkt auf dem Host und ist in die Container
gemountet – einfach die Dateien bearbeiten:

| Sprache | Ordner            | Änderung wird sichtbar nach …          |
|---------|-------------------|----------------------------------------|
| PHP     | `php/www/`        | sofort (Seite neu laden)               |
| Python  | `python/app/`     | `docker compose restart python`        |
| Node.js | `node/app/`       | `docker compose restart node`          |

Die DB-Zugangsdaten stehen in jedem Container als Umgebungs-
variablen bereit: `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`.
Als `DB_HOST` immer `db` verwenden (der Container-Name der Datenbank).

---

## 7. Nützliche Befehle

```bash
# Logs ansehen (alle oder ein Container)
docker compose logs -f
docker compose logs -f php

# In einen Container hineingehen
docker compose exec php bash
docker compose exec db bash

# Umgebung stoppen (Daten bleiben erhalten)
docker compose down

# Umgebung stoppen UND Datenbank zurücksetzen
#   -> beim nächsten Start läuft sql/init/ wieder
docker compose down -v
```

---

## 8. Fehlerbehebung

| Problem                               | Lösung                                                                 |
|---------------------------------------|------------------------------------------------------------------------|
| „Port is already allocated“           | In `.env` den jeweiligen Port ändern, dann `docker compose up -d`       |
| DB-Verbindung rot auf der Demo-Seite  | Kurz warten (DB startet 10–20 s), Seite neu laden                      |
| `sql/init/` lief nicht                | DB hatte schon Daten → `docker compose down -v`, dann neu starten      |
| Änderung am Python/Node-Code fehlt    | `docker compose restart python` bzw. `node`                            |
| Komplett neu aufsetzen                | `docker compose down -v` und danach `docker compose up -d --build`     |

---

## 9. Projektstruktur

```
.
├── .env                  # Zugangsdaten (nicht in Git)
├── .env.example          # Vorlage für .env
├── .gitignore
├── docker-compose.yml    # Definition aller Container
├── run-sql.sh            # Helfer: SQL-Datei auf der DB ausführen
├── README.md
├── php/
│   ├── Dockerfile
│   └── www/index.php     # PHP-Demo (hier eigenen Code ablegen)
├── python/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/app.py        # Python-Demo
├── node/
│   ├── Dockerfile
│   └── app/
│       ├── package.json
│       └── server.js     # Node-Demo
└── sql/
    ├── init/01-schema.sql    # läuft automatisch beim 1. Start
    └── scripts/beispiel.sql  # manuell via ./run-sql.sh
```
# TR-bewerberplattform
