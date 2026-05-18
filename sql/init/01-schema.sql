-- ============================================================
--  Wird AUTOMATISCH beim allerersten Start des DB-Containers
--  ausgeführt (Reihenfolge nach Dateiname: 01-, 02- ...).
--
--  WICHTIG: läuft nur, solange noch keine Daten existieren.
--  Zum erneuten Ausführen: siehe README -> "Datenbank zurücksetzen".
--
--  Für eigene Skripte im laufenden Betrieb: ./run-sql.sh nutzen.
-- ============================================================

CREATE TABLE IF NOT EXISTS bewerber (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    vorname     VARCHAR(100) NOT NULL,
    nachname    VARCHAR(100) NOT NULL,
    email       VARCHAR(190) NOT NULL UNIQUE,
    erstellt_am TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO bewerber (vorname, nachname, email) VALUES
    ('Erika',  'Mustermann', 'erika@example.com'),
    ('Max',    'Mustermann', 'max@example.com');
