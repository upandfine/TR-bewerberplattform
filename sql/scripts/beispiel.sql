-- ============================================================
--  Beispiel-DDL zum Ausprobieren.
--  Ausführen mit:
--      ./run-sql.sh sql/scripts/beispiel.sql
--
--  Lege hier gern eigene .sql-Dateien an.
-- ============================================================

CREATE TABLE IF NOT EXISTS stellenanzeige (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    titel       VARCHAR(150) NOT NULL,
    standort    VARCHAR(100) NOT NULL,
    erstellt_am TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO stellenanzeige (titel, standort) VALUES
    ('Fachinformatiker/in Anwendungsentwicklung', 'Remote'),
    ('Fachinformatiker/in Systemintegration',     'Berlin');

SELECT * FROM stellenanzeige;
