# Lernumgebung Fachinformatiker

Eine einfache Docker-Umgebung mit Datenbank und drei Webservern
(PHP, Python, Node.js) sowie phpMyAdmin. Gedacht für Teilnehmende
einer Umschulung zum Fachinformatiker – mit sinnvollen Standardwerten,
damit es ohne lange Einrichtung läuft.

---

## 1. Was ist enthalten?

| Container    | Technologie            | Adresse im Browser              |
|--------------|------------------------|---------------------------------|
| `db`         | MariaDB 11             | (nur intern, Port 3306)         |
| `php`        | PHP 8.4 + Apache       | http://localhost:8080           |
| `python`     | Python 3.12 (Flask)    | http://localhost:8001           |
| `node`       | Node.js 22 (Express)   | http://localhost:3000           |
| `dotnet`     | .NET 9 / ASP.NET Core  | http://localhost:8082           |
| `java`       | Java 21 / Spring Boot  | http://localhost:8083           |
| `kotlin`     | Kotlin 2 / Ktor        | http://localhost:8084           |
| `go`         | Go 1.23 / chi          | http://localhost:8085           |
| `ruby`       | Ruby 3.3 / Sinatra     | http://localhost:8086           |
| `vue`        | Vue 3 (Vite + nginx)   | http://localhost:5173           |
| `phpmyadmin` | phpMyAdmin             | http://localhost:8081           |
| `nocodb`     | NocoDB (Daten-UI)      | http://localhost:8090           |

Die Ports lassen sich in der Datei `.env` ändern, falls einer
auf deinem Rechner schon belegt ist.

phpMyAdmin = SQL/DDL · NocoDB = komfortables Arbeiten auf den
Daten (siehe Abschnitt 6b).

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
- .NET:       http://localhost:8082
- Vue-Form:   http://localhost:5173
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
| `MARIADB_DATABASE`       | Name der Datenbank                 | `bewerbung_db`     |
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

Die mitgelieferte Datei `sql/init/init_bewerbung.sql` legt das
vollständige Bewerbermanagement-Schema (Datenbank `bewerbung_db`,
8 Tabellen mit Fremdschlüsseln) plus kleine Demo-Daten an.

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

> **Windows-Hinweis (PowerShell):** Statt `./run-sql.sh` das
> mitgelieferte PowerShell-Pendant nutzen – funktioniert in
> Windows PowerShell 5.1 und PowerShell 7+:
>
> ```powershell
> .\run-sql.ps1 sql\scripts\meins.sql
> ```
>
> Alternativ über Git Bash mit dem normalen Bash-Skript:
> `bash run-sql.sh sql/scripts/meins.sql`.

### Massendaten zum Üben (Demo-Datensatz)

Für realistische Datenmengen liegen zwei Skripte bereit:

```bash
# ~500 Bewerber auf 12 Stellen, ALLE Tabellen mit echten Relationen
./run-sql.sh sql/scripts/demo-seed.sql

# räumt NUR diese Demo-Daten wieder ab (Init-Daten bleiben)
./run-sql.sh sql/scripts/demo-clear.sql
```

`demo-seed.sql` erzeugt u. a. ~625 Bewerbungen, ~1150 Dokumente,
~480 Bewertungen (inkl. 4-Augen-Fällen), Status-Historie und
DSGVO-Einwilligungen. Alle Demo-Zeilen sind eindeutig markiert
(z. B. E-Mail `…@demo.example`, `vorgangsNr` `BW-D…`), damit
`demo-clear.sql` gezielt löscht, ohne die Init-Demodaten (Anna)
anzutasten. Ideal, um NocoDB/phpMyAdmin mit Inhalt zu zeigen.

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

## 6a. Durchstich: Bewerbung-API + Tests (PHP)

Ein minimaler vertikaler Durchstich (Walking Skeleton) als Beispiel
für saubere, testbare Architektur. Drei dünne Schichten in
`php/src/`:

| Schicht | Datei | Aufgabe | Testart |
|---|---|---|---|
| HTTP | `php/www/api.php` | Request/Response-Mapping | API/E2E |
| Use-Case | `src/BewerbungService.php` | reine Fachlogik, kein DB/HTTP | Unit |
| Persistenz | `src/PdoBewerbungRepository.php` | SQL gegen MariaDB | Integration |

Die Naht zwischen Service und Persistenz ist
`src/BewerbungRepositoryInterface.php` – im Unit-Test durch ein
In-Memory-Fake ersetzt, daher ohne Datenbank lauffähig.

### Vorbereiten

Keine Vorbereitung nötig: Schema **und** eine Beispiel-Stelle
werden beim ersten DB-Start automatisch aus
`sql/init/init_bewerbung.sql` angelegt. Falls die DB schon
existiert, einmalig zurücksetzen:

```bash
docker compose down -v && docker compose up -d
```

### API ausprobieren

```bash
# Bewerbung einreichen
curl -X POST http://localhost:8080/api.php \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Bewerbungen auflisten (optional ?status=EINGEGANGEN)
curl http://localhost:8080/api.php
```

### Tests ausführen

```bash
# Alle Tests (Unit + Integration + API)
docker compose exec php php vendor/bin/phpunit --testdox

# Nur eine Ebene
docker compose exec php php vendor/bin/phpunit --testsuite unit
docker compose exec php php vendor/bin/phpunit --testsuite integration
docker compose exec php php vendor/bin/phpunit --testsuite api
```

> Bewusst NICHT im Scope: Auth, Datei-Upload, E-Mail, UI,
> Status-Workflow-Übergänge. Nur JSON-API – als Fundament, auf dem
> die TN weitere Tests und Features aufbauen.

---

## 6b. NocoDB – komfortabel auf den Daten arbeiten

NocoDB ist eine Airtable-artige Oberfläche zum **Bearbeiten der
Daten** (Datensätze anlegen/ändern, Filtern, Kanban). Es liest das
Schema der MariaDB automatisch ein – Tabellen, Fremdschlüssel und
ENUMs erscheinen ohne Konfiguration.

> Aufgabenteilung: **phpMyAdmin** für SQL/DDL (Tabellen anlegen,
> SQL üben), **NocoDB** für bequemes Arbeiten an den Daten.

### Einmalige Einrichtung (~2 Minuten)

1. http://localhost:8090 öffnen und ein **Admin-Konto** anlegen
   (frei wählbar, nur lokal).
2. **Create Base → Connect to External Database → MySQL** wählen.
3. Verbindungsdaten eintragen (Werte aus der `.env`):

   | Feld     | Wert                |
   |----------|---------------------|
   | Host     | `db`                |
   | Port     | `3306`              |
   | Username | `app`               |
   | Password | `apppass`           |
   | Database | `bewerbung_db`      |

4. **Test Connection → Submit**. NocoDB importiert alle Tabellen
   automatisch; Fremdschlüssel werden als verknüpfte Datensätze
   dargestellt.

> `Host = db` ist der Container-Name der Datenbank im internen
> Docker-Netz – nicht `localhost`.

### Tipp für die Schulung

In der Tabelle `bewerbung` die Ansicht auf **Kanban** umstellen und
nach `status` gruppieren – damit sieht man den Bewerbungs-Workflow
als Board (sehr anschaulich).

---

## 6c. Derselbe Durchstich in acht Sprachen

Exakt dieselbe Architektur und API wie 6a – einmal je Stack, alle
gegen dieselbe `bewerbung_db`. Ideal zum Sprachvergleich in der
Schulung: identische drei Schichten, identischer JSON-Vertrag,
identische Test-Sorten (Unit ohne DB, Integration gegen echte DB,
API über HTTP).

| Stack | Port | HTTP | Use-Case | Persistenz | Interface |
|---|---|---|---|---|---|
| PHP 8.4 / Apache       | 8080 | `php/www/api.php` | `php/src/BewerbungService.php` | `php/src/PdoBewerbungRepository.php` | `BewerbungRepositoryInterface.php` |
| Python 3.12 / Flask    | 8001 | `python/app/app.py` | `python/app/service.py` | `python/app/repository.py` | `BewerbungRepository` (Protocol) |
| Node.js 22 / Express   | 3000 | `node/app/server.js` | `node/app/service.js` | `node/app/repository.js` | Duck-Typing / Fake |
| .NET 9 / ASP.NET Core  | 8082 | `dotnet/src/Bewerbung.Api/Program.cs` | `dotnet/src/Bewerbung.Api/BewerbungService.cs` | `dotnet/src/Bewerbung.Api/MySqlBewerbungRepository.cs` | `IBewerbungRepository.cs` |
| Java 21 / Spring Boot  | 8083 | `java/src/main/java/de/train/bewerbung/BewerbungController.java` | `java/src/main/java/de/train/bewerbung/BewerbungService.java` | `java/src/main/java/de/train/bewerbung/JdbcBewerbungRepository.java` | `BewerbungRepository.java` |
| Kotlin 2 / Ktor        | 8084 | `kotlin/src/main/kotlin/de/train/bewerbung/App.kt` | `kotlin/src/main/kotlin/de/train/bewerbung/Service.kt` | `kotlin/src/main/kotlin/de/train/bewerbung/Repository.kt` | `BewerbungRepository` (interface in `Repository.kt`) |
| Go 1.23 / chi          | 8085 | `go/app/server.go` | `go/app/service.go` | `go/app/repository.go` | `BewerbungRepository` (interface in `repository.go`) |
| Ruby 3.3 / Sinatra     | 8086 | `ruby/app/app.rb` | `ruby/app/service.rb` | `ruby/app/repository.rb` | Duck-Typing / Fake |

> Kotlin-Wahl: **Ktor** statt Spring Boot — leichter, schnellerer
> Start im Container, kein Reflection-/Annotation-Overhead.
> Spring Boot deckt der Java-Stack bereits ab; Ktor zeigt einen
> dazu kontrastierenden "leichtgewichtigen" Ansatz.

Endpunkte (identischer JSON-Vertrag, snake_case-Ausgabe):

```bash
# PHP        ->  Port 8080 (Endpoint hier: /api.php)
curl -X POST http://localhost:8080/api.php \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Python     ->  Port 8001
curl -X POST http://localhost:8001/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Node       ->  Port 3000
curl -X POST http://localhost:3000/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# C# / .NET  ->  Port 8082
curl -X POST http://localhost:8082/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Java       ->  Port 8083
curl -X POST http://localhost:8083/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Kotlin     ->  Port 8084
curl -X POST http://localhost:8084/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Go         ->  Port 8085
curl -X POST http://localhost:8085/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Ruby       ->  Port 8086
curl -X POST http://localhost:8086/api/bewerbungen \
  -H 'Content-Type: application/json' \
  -d '{"vorname":"Erika","nachname":"Mustermann","email":"e@example.com","stelle_id":1}'

# Auflisten (gleiche Pfade, GET):
curl http://localhost:8001/api/bewerbungen
```

Tests pro Stack (Unit ohne DB, Integration gegen echte DB, API über HTTP):

```bash
# PHP: PHPUnit
docker compose exec php php vendor/bin/phpunit --testdox

# Python: pytest
docker compose exec python python -m pytest -q tests

# Node: eingebauter Test-Runner
docker compose exec node npm test

# C#: xUnit
docker compose exec -w /work dotnet dotnet test tests/Bewerbung.Tests --nologo

# Java: JUnit 5 (Maven Surefire)
docker compose exec -w /work java mvn -B -Dmaven.repo.local=/maven-cache test

# Kotlin: JUnit 5 (Maven Surefire)
docker compose exec -w /work kotlin mvn -B -Dmaven.repo.local=/maven-cache test

# Go: Unit (ohne DB)
docker compose exec -w /work go go test ./app/...
# Go: Integration + API (mit Build-Tag "integration")
docker compose exec -w /work go go test -tags=integration ./app/...

# Ruby: Minitest (alle Tests)
docker compose exec -w /app ruby bundle exec rake test
```

> Hinweis: Code-Änderungen werden nach
> `docker compose restart <service>` aktiv (z. B. `python`, `node`,
> `dotnet`, `java`, `kotlin`, `go`, `ruby`).

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
├── run-sql.sh            # Helfer (macOS/Linux/Git Bash): SQL auf der DB ausführen
├── run-sql.ps1           # Helfer (Windows PowerShell): dasselbe für PS 5.1 / 7+
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
│   ├── app/              # Express-API (siehe 6c)
│   └── tests/            # node --test
├── dotnet/
│   ├── Dockerfile
│   ├── src/Bewerbung.Api/   # ASP.NET Core Minimal API (siehe 6c)
│   └── tests/Bewerbung.Tests/  # xUnit
├── java/
│   ├── Dockerfile
│   ├── pom.xml          # Maven + Spring Boot 3.4
│   └── src/             # main/java + test/java (JUnit 5)
├── kotlin/
│   ├── Dockerfile
│   ├── pom.xml          # Maven + Ktor 2.3
│   └── src/             # main/kotlin + test/kotlin (JUnit 5)
├── go/
│   ├── Dockerfile
│   ├── go.mod / go.sum
│   └── app/             # main-Paket inkl. *_test.go (Unit + Integration)
├── ruby/
│   ├── Dockerfile
│   ├── Gemfile / Gemfile.lock
│   ├── Rakefile
│   ├── app/             # Sinatra-App (config.ru, app.rb, service.rb, ...)
│   └── tests/           # Minitest
├── vue/
│   ├── Dockerfile           # multi-stage: vite build -> nginx
│   ├── nginx.conf
│   ├── index.html
│   ├── vite.config.js
│   ├── package.json
│   └── src/                 # App.vue, main.js, styles.css
└── sql/
    ├── init/init_bewerbung.sql  # Schema + Demo, automatisch beim 1. Start
    └── scripts/
        ├── beispiel.sql     # generisches Beispiel, manuell via ./run-sql.sh
        ├── demo-seed.sql    # ~500 Bewerber + alle Tabellen befüllen
        └── demo-clear.sql   # Demo-Daten wieder entfernen
```

---

## 7. Vue-Formular (`vue`)

Kleine Single-Page-App (Vue 3 + Vite, im Container von nginx ausgeliefert),
mit der man eine Bewerbung an eines der vier Backends schicken kann.

Aufruf: <http://localhost:5173>

Im Formular auswählbar:

- **Backend-Typ:** PHP, Python, Node oder .NET. Damit weiß die App, ob
  sie an `/api.php` (PHP) oder `/api/bewerbungen` (alle anderen) schicken muss.
- **Basis-URL:** z.B. `http://localhost:8080`. Lässt sich frei ändern,
  falls Ports in `.env` verschoben wurden.

Felder gemäß DB-Schema:

| Feld        | Pflicht | Hinweis                              |
|-------------|---------|--------------------------------------|
| Vorname     | ja      | max. 60 Zeichen                      |
| Nachname    | ja      | max. 60 Zeichen                      |
| E-Mail      | ja      | UNIQUE auf `bewerber.email`          |
| Telefon     | nein    | max. 30 Zeichen                      |
| Stellen-ID  | ja      | FK auf `stellenangebot.id`           |
| Bemerkung   | nein    | max. 500 Zeichen                     |

Bei Erfolg zeigt das Formular `vorgangs_nr`, `bewerbung_id`
und `bewerber_id` an. Fehler (Validierung, FK, Duplikat) werden
mit HTTP-Status und Details ausgegeben.

> CORS: Alle vier Backends senden `Access-Control-Allow-Origin: *`,
> damit der Browser den Cross-Origin-Request vom Vue-Container
> (Port 5173) auf das Backend (8080/8001/3000/8082) erlaubt.

---

## CI/CD-Demo

Im Repo liegen zwei Beispiel-Workflows für GitHub Actions, die
das klassische Drei-Stage-Modell **dev → demo → live** zeigen:

- [.github/workflows/ci.yml](.github/workflows/ci.yml) — Tests
  und Docker-Probebau bei jedem Push / PR.
- [.github/workflows/cd.yml](.github/workflows/cd.yml) — Build,
  Push nach GHCR, Deploy je Stage (live mit manuellem Gate).

Ausführliche Erklärung inkl. Trigger-Modell, Setup-Schritten
und Beispielen für echte Deploy-Befehle: [CICD.md](CICD.md).
