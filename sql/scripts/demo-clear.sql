-- =====================================================================
--  demo-clear.sql
--  Entfernt ausschließlich die von demo-seed.sql erzeugten Daten.
--  Die Init-Demodaten aus sql/init/init_bewerbung.sql (Anna,
--  'Werkstudent:in Backend', BW-2026-0001 ...) bleiben unberührt.
--
--  Ausführen: ./run-sql.sh sql/scripts/demo-clear.sql
--
--  Löschreihenfolge nach Fremdschlüsseln:
--   - bewerbung zuerst -> CASCADE räumt dokument / bewertung /
--     status_history automatisch ab
--   - bewerber danach  -> CASCADE räumt einwilligung ab
--   - hr_mitarbeiter & stellenangebot zuletzt (ON DELETE RESTRICT,
--     daher erst nachdem alle Bewerbungen/Bewertungen weg sind)
-- =====================================================================

USE bewerbung_db;

START TRANSACTION;

DELETE FROM bewerbung      WHERE vorgangsNr LIKE 'BW-D%';
DELETE FROM bewerber       WHERE email      LIKE '%@demo.example';
DELETE FROM hr_mitarbeiter  WHERE email      LIKE '%@demo.hr';
DELETE FROM stellenangebot WHERE beschreibung LIKE '[DEMO]%';

COMMIT;

-- Kontrolle: sollte überall 0 sein
SELECT 'stellenangebot' AS tabelle, COUNT(*) AS rest
  FROM stellenangebot WHERE beschreibung LIKE '[DEMO]%'
UNION ALL SELECT 'hr_mitarbeiter', COUNT(*) FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr'
UNION ALL SELECT 'bewerber',       COUNT(*) FROM bewerber       WHERE email LIKE '%@demo.example'
UNION ALL SELECT 'bewerbung',      COUNT(*) FROM bewerbung      WHERE vorgangsNr LIKE 'BW-D%';

-- =====================================================================
-- Ende demo-clear.sql
-- =====================================================================
