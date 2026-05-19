-- =====================================================================
--  demo-seed.sql
--  Erzeugt ca. 500 Bewerber auf 12 Stellen, alle Tabellen logisch
--  gefüllt mit echten Relationen.
--
--  Zielschema : bewerbung_db (siehe sql/init/init_bewerbung.sql)
--  Ausführen  : ./run-sql.sh sql/scripts/demo-seed.sql
--  Löschen    : ./run-sql.sh sql/scripts/demo-clear.sql
--
--  Eindeutige Marker (damit demo-clear.sql gezielt löschen kann,
--  ohne die Init-Demodaten anzufassen):
--    - bewerber.email        endet auf '@demo.example'
--    - hr_mitarbeiter.email  endet auf '@demo.hr'
--    - stellenangebot.beschreibung beginnt mit '[DEMO]'
--    - bewerbung.vorgangsNr  beginnt mit 'BW-D'
--  Abhängige Tabellen (dokument/bewertung/status_history/einwilligung)
--  hängen per Fremdschlüssel an diesen Markern.
-- =====================================================================

USE bewerbung_db;

START TRANSACTION;

-- ----------------------------------------------------------------------
-- 1. 12 Stellenangebote
-- ----------------------------------------------------------------------
INSERT INTO stellenangebot (titel, beschreibung, art, status, erstelltAm, veroeffentlichtAm)
SELECT
    ELT(seq,
        'Fachinformatiker/in Anwendungsentwicklung',
        'Fachinformatiker/in Systemintegration',
        'Werkstudent/in Backend',
        'Werkstudent/in Frontend',
        'Software-Entwickler/in Java',
        'Software-Entwickler/in PHP',
        'DevOps Engineer',
        'Datenbank-Administrator/in',
        'IT-Projektleiter/in',
        'UX/UI-Designer/in',
        'QA-/Test-Engineer',
        'Auszubildende/r FIAE'),
    CONCAT('[DEMO] Beschreibung zur Stelle ', seq, ' – Aufgaben, Profil, Benefits.'),
    ELT(1 + (seq % 5), 'FESTANSTELLUNG','AZUBI','MINIJOB','WERKSTUDENT','PRAKTIKUM'),
    'VEROEFFENTLICHT',
    NOW() - INTERVAL (90 + seq) DAY,
    NOW() - INTERVAL (75 + seq) DAY
FROM seq_1_to_12;

-- ----------------------------------------------------------------------
-- 2. 8 HR-Mitarbeitende
-- ----------------------------------------------------------------------
INSERT INTO hr_mitarbeiter (name, email, rolle, aktiv)
SELECT
    CONCAT(ELT(seq,'Sina','Tom','Mara','Jens','Lea','Paul','Nora','Kai'), ' Demo'),
    CONCAT('hr', seq, '@demo.hr'),
    ELT(1 + (seq % 4), 'RECRUITER','HR_LEAD','FACH_REVIEWER','ADMIN'),
    IF(seq % 7 = 0, FALSE, TRUE)
FROM seq_1_to_8;

-- ----------------------------------------------------------------------
-- 3. 500 Bewerber
-- ----------------------------------------------------------------------
INSERT INTO bewerber (vorname, nachname, email, telefon, geburtsdatum, anschrift, angelegtAm)
SELECT
    ELT(1 + (seq % 20),
        'Anna','Ben','Clara','David','Ela','Finn','Greta','Hugo','Ida','Jonas',
        'Klara','Liam','Mia','Noah','Ole','Pia','Quentin','Rosa','Sami','Tara'),
    ELT(1 + ((seq * 7) % 20),
        'Albrecht','Bauer','Conrad','Decker','Engel','Faber','Gross','Hahn','Iben','Jung',
        'Kaiser','Lang','Meyer','Naumann','Ott','Peters','Quast','Richter','Schulz','Thiel'),
    CONCAT('bewerber', LPAD(seq, 3, '0'), '@demo.example'),
    CONCAT('+49 170 ', LPAD(seq, 7, '0')),
    DATE('1980-01-01') + INTERVAL (seq * 11 % 9000) DAY,
    CONCAT('Musterstr. ', 1 + (seq % 200), ', ',
           LPAD(10000 + (seq * 7 % 79999), 5, '0'), ' Musterstadt'),
    NOW() - INTERVAL (seq % 120) DAY
FROM seq_1_to_500;

-- ----------------------------------------------------------------------
-- 4. Bewerbungen
--    4a) Primärbewerbung: jeder der 500 bewirbt sich auf eine Stelle
--    4b) Zusatzbewerbung: jeder 4. zusätzlich auf eine ANDERE Stelle
--        (erfüllt die n:m-Beziehung Bewerber<->Stelle ohne Verstoß
--         gegen UNIQUE(bewerberId, stelleId))
-- ----------------------------------------------------------------------
INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, eingangAm, status, bemerkung)
SELECT
    db.id, ds.id,
    CONCAT('BW-D1-', LPAD(db.rn, 6, '0')),
    db.angelegtAm + INTERVAL (db.rn % 10) DAY,
    ELT(1 + (db.rn % 7),
        'EINGEGANGEN','IN_PRUEFUNG','INTERVIEW','ANGEBOT',
        'ABGELEHNT','ZURUECKGEZOGEN','EINGESTELLT'),
    CONCAT('Eingang über Demo-Seed (', db.rn, ')')
FROM (SELECT id, angelegtAm, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM bewerber WHERE email LIKE '%@demo.example') db
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM stellenangebot WHERE beschreibung LIKE '[DEMO]%') ds
  ON ds.rn = 1 + ((db.rn - 1) % 12);

INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, eingangAm, status, bemerkung)
SELECT
    db.id, ds.id,
    CONCAT('BW-D2-', LPAD(db.rn, 6, '0')),
    db.angelegtAm + INTERVAL (3 + db.rn % 10) DAY,
    ELT(1 + (db.rn % 5),
        'EINGEGANGEN','IN_PRUEFUNG','INTERVIEW','ABGELEHNT','ZURUECKGEZOGEN'),
    'Zweitbewerbung über Demo-Seed'
FROM (SELECT id, angelegtAm, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM bewerber WHERE email LIKE '%@demo.example') db
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM stellenangebot WHERE beschreibung LIKE '[DEMO]%') ds
  ON ds.rn = 1 + (db.rn % 12)
WHERE db.rn % 4 = 0;

-- ----------------------------------------------------------------------
-- 5. Status-History (Audit-Spur)
--    - Initialeintrag (NULL -> EINGEGANGEN) für jede Bewerbung
--    - Übergang (EINGEGANGEN -> aktueller Status) falls abweichend
-- ----------------------------------------------------------------------
INSERT INTO status_history (bewerbungId, hrMaId, alterStatus, neuerStatus, geaendertAm)
SELECT b.id, dh.id, NULL, 'EINGEGANGEN', b.eingangAm
FROM bewerbung b
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr') dh
  ON dh.rn = 1 + (b.id % 8)
WHERE b.vorgangsNr LIKE 'BW-D%';

INSERT INTO status_history (bewerbungId, hrMaId, alterStatus, neuerStatus, geaendertAm)
SELECT b.id, dh.id, 'EINGEGANGEN', b.status, b.eingangAm + INTERVAL 3 DAY
FROM bewerbung b
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr') dh
  ON dh.rn = 1 + (b.id % 8)
WHERE b.vorgangsNr LIKE 'BW-D%'
  AND b.status <> 'EINGEGANGEN';

-- ----------------------------------------------------------------------
-- 6. Dokumente
--    - Lebenslauf für alle, Anschreiben für jede 2., Zeugnis für jede 3.
-- ----------------------------------------------------------------------
INSERT INTO dokument (bewerbungId, typ, dateiname, dateigroesse, mimeType, gespeichertPfad, hochgeladenAm)
SELECT b.id, 'LEBENSLAUF',
       CONCAT('lebenslauf_', b.vorgangsNr, '.pdf'),
       200000 + (b.id * 131 % 9000000), 'application/pdf',
       CONCAT('/storage/demo/', b.vorgangsNr, '/lebenslauf.pdf'), b.eingangAm
FROM bewerbung b WHERE b.vorgangsNr LIKE 'BW-D%';

INSERT INTO dokument (bewerbungId, typ, dateiname, dateigroesse, mimeType, gespeichertPfad, hochgeladenAm)
SELECT b.id, 'ANSCHREIBEN',
       CONCAT('anschreiben_', b.vorgangsNr, '.pdf'),
       80000 + (b.id * 97 % 1500000), 'application/pdf',
       CONCAT('/storage/demo/', b.vorgangsNr, '/anschreiben.pdf'), b.eingangAm
FROM bewerbung b WHERE b.vorgangsNr LIKE 'BW-D%' AND b.id % 2 = 0;

INSERT INTO dokument (bewerbungId, typ, dateiname, dateigroesse, mimeType, gespeichertPfad, hochgeladenAm)
SELECT b.id, 'ZEUGNIS',
       CONCAT('zeugnis_', b.vorgangsNr, '.pdf'),
       300000 + (b.id * 211 % 4000000), 'application/pdf',
       CONCAT('/storage/demo/', b.vorgangsNr, '/zeugnis.pdf'), b.eingangAm
FROM bewerbung b WHERE b.vorgangsNr LIKE 'BW-D%' AND b.id % 3 = 0;

-- ----------------------------------------------------------------------
-- 7. Bewertungen
--    - Eine Bewertung für fortgeschrittene Stati
--    - Zweite Bewertung (4-Augen) für ANGEBOT / EINGESTELLT,
--      durch eine ANDERE HR-Person (UNIQUE bewerbungId,hrMaId ok)
-- ----------------------------------------------------------------------
INSERT INTO bewertung (bewerbungId, hrMaId, score, kommentar, empfehlung, datum)
SELECT b.id, dh.id,
       1 + (b.id % 5),
       CONCAT('Demo-Bewertung zu ', b.vorgangsNr),
       CASE
           WHEN 1 + (b.id % 5) >= 4 THEN 'EINSTELLEN'
           WHEN 1 + (b.id % 5) =  3 THEN 'WEITER_PRUEFEN'
           ELSE 'ABLEHNEN'
       END,
       b.eingangAm + INTERVAL 5 DAY
FROM bewerbung b
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr') dh
  ON dh.rn = 1 + (b.id % 8)
WHERE b.vorgangsNr LIKE 'BW-D%'
  AND b.status IN ('INTERVIEW','ANGEBOT','ABGELEHNT','EINGESTELLT');

INSERT INTO bewertung (bewerbungId, hrMaId, score, kommentar, empfehlung, datum)
SELECT b.id, dh.id,
       1 + ((b.id + 2) % 5),
       CONCAT('Zweitbewertung (4-Augen) zu ', b.vorgangsNr),
       CASE
           WHEN 1 + ((b.id + 2) % 5) >= 4 THEN 'EINSTELLEN'
           WHEN 1 + ((b.id + 2) % 5) =  3 THEN 'WEITER_PRUEFEN'
           ELSE 'ABLEHNEN'
       END,
       b.eingangAm + INTERVAL 7 DAY
FROM bewerbung b
JOIN (SELECT id, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr') dh
  ON dh.rn = 1 + ((b.id + 1) % 8)
WHERE b.vorgangsNr LIKE 'BW-D%'
  AND b.status IN ('ANGEBOT','EINGESTELLT');

-- ----------------------------------------------------------------------
-- 8. Einwilligungen (DSGVO) – eine je Bewerber, jede 10. widerrufen
-- ----------------------------------------------------------------------
INSERT INTO einwilligung (bewerberId, version, gegebenAm, widerrufenAm)
SELECT db.id, '2026-01', db.angelegtAm,
       IF(db.rn % 10 = 0, db.angelegtAm + INTERVAL 30 DAY, NULL)
FROM (SELECT id, angelegtAm, ROW_NUMBER() OVER (ORDER BY id) rn
      FROM bewerber WHERE email LIKE '%@demo.example') db;

COMMIT;

-- ----------------------------------------------------------------------
-- 9. Kontroll-Übersicht
-- ----------------------------------------------------------------------
SELECT 'stellenangebot' AS tabelle, COUNT(*) AS demo_zeilen
  FROM stellenangebot WHERE beschreibung LIKE '[DEMO]%'
UNION ALL SELECT 'hr_mitarbeiter', COUNT(*) FROM hr_mitarbeiter WHERE email LIKE '%@demo.hr'
UNION ALL SELECT 'bewerber',       COUNT(*) FROM bewerber       WHERE email LIKE '%@demo.example'
UNION ALL SELECT 'bewerbung',      COUNT(*) FROM bewerbung      WHERE vorgangsNr LIKE 'BW-D%'
UNION ALL SELECT 'dokument',       COUNT(*) FROM dokument d
            JOIN bewerbung b ON b.id = d.bewerbungId WHERE b.vorgangsNr LIKE 'BW-D%'
UNION ALL SELECT 'bewertung',      COUNT(*) FROM bewertung v
            JOIN bewerbung b ON b.id = v.bewerbungId WHERE b.vorgangsNr LIKE 'BW-D%'
UNION ALL SELECT 'status_history', COUNT(*) FROM status_history s
            JOIN bewerbung b ON b.id = s.bewerbungId WHERE b.vorgangsNr LIKE 'BW-D%'
UNION ALL SELECT 'einwilligung',   COUNT(*) FROM einwilligung e
            JOIN bewerber bw ON bw.id = e.bewerberId WHERE bw.email LIKE '%@demo.example';

-- =====================================================================
-- Ende demo-seed.sql
-- =====================================================================
