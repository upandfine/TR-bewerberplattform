-- =====================================================================
--  init_bewerbung.sql
--  Musterloesung: Init-Script fuer ein Bewerbermanagement-System
--  Zielsystem  : MariaDB 10.4+
--  Zeichensatz : utf8mb4 / utf8mb4_unicode_ci
--  Engine      : InnoDB (fuer Foreign Keys und Transaktionen)
--
--  Wird beim ERSTEN Start des DB-Containers automatisch ausgefuehrt.
--  Erneut anwenden: docker compose down -v && docker compose up -d
-- =====================================================================

-- ----------------------------------------------------------------------
-- 0. Datenbank anlegen und auswaehlen
-- ----------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS bewerbung_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE bewerbung_db;

-- Damit das Script mehrfach lauffaehig ist: Tabellen in umgekehrter
-- Abhaengigkeitsreihenfolge entfernen.
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS einwilligung;
DROP TABLE IF EXISTS status_history;
DROP TABLE IF EXISTS bewertung;
DROP TABLE IF EXISTS dokument;
DROP TABLE IF EXISTS bewerbung;
DROP TABLE IF EXISTS hr_mitarbeiter;
DROP TABLE IF EXISTS stellenangebot;
DROP TABLE IF EXISTS bewerber;
SET FOREIGN_KEY_CHECKS = 1;


-- ----------------------------------------------------------------------
-- 1. Stammtabellen (ohne Fremdschluessel)
-- ----------------------------------------------------------------------

-- Tabelle: bewerber
-- Zweck  : Stammdaten einer Bewerberin / eines Bewerbers
CREATE TABLE bewerber (
    id            INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    vorname       VARCHAR(60)    NOT NULL,
    nachname      VARCHAR(60)    NOT NULL,
    email         VARCHAR(120)   NOT NULL,
    telefon       VARCHAR(30)    NULL,
    geburtsdatum  DATE           NULL,
    anschrift     VARCHAR(255)   NULL,
    angelegtAm    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_bewerber_email (email),
    KEY idx_bewerber_nachname (nachname),
    CONSTRAINT chk_bewerber_email
        CHECK (email LIKE '%_@_%.__%')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: stellenangebot
-- Zweck  : Offene oder archivierte Stellen, fuer die man sich bewerben kann
CREATE TABLE stellenangebot (
    id              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    titel           VARCHAR(120)  NOT NULL,
    beschreibung    TEXT          NULL,
    art             ENUM('FESTANSTELLUNG','AZUBI','MINIJOB','WERKSTUDENT','PRAKTIKUM')
                                  NOT NULL DEFAULT 'FESTANSTELLUNG',
    status          ENUM('ENTWURF','VEROEFFENTLICHT','GESCHLOSSEN','ARCHIVIERT')
                                  NOT NULL DEFAULT 'ENTWURF',
    erstelltAm      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    veroeffentlichtAm DATETIME    NULL,
    PRIMARY KEY (id),
    KEY idx_stelle_status (status),
    KEY idx_stelle_art    (art),
    CONSTRAINT chk_stelle_veroeff
        CHECK (veroeffentlichtAm IS NULL OR veroeffentlichtAm >= erstelltAm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: hr_mitarbeiter
-- Zweck  : Mitarbeitende, die Bewerbungen bearbeiten / bewerten
CREATE TABLE hr_mitarbeiter (
    id     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name   VARCHAR(120)  NOT NULL,
    email  VARCHAR(120)  NOT NULL,
    rolle  ENUM('RECRUITER','HR_LEAD','FACH_REVIEWER','ADMIN')
                         NOT NULL DEFAULT 'RECRUITER',
    aktiv  BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id),
    UNIQUE KEY uq_hr_email (email),
    KEY idx_hr_aktiv (aktiv)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------------
-- 2. Abhaengige Tabellen (mit Fremdschluesseln)
-- ----------------------------------------------------------------------

-- Tabelle: bewerbung
-- Zweck  : Verknuepft Bewerber mit einer konkreten Stelle
CREATE TABLE bewerbung (
    id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    bewerberId INT UNSIGNED  NOT NULL,
    stelleId   INT UNSIGNED  NOT NULL,
    vorgangsNr VARCHAR(20)   NOT NULL,
    eingangAm  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status     ENUM('EINGEGANGEN','IN_PRUEFUNG','INTERVIEW','ANGEBOT','ABGELEHNT','ZURUECKGEZOGEN','EINGESTELLT')
                             NOT NULL DEFAULT 'EINGEGANGEN',
    bemerkung  VARCHAR(500)  NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_bewerbung_vorgangsnr (vorgangsNr),
    -- Eine Person darf sich nicht zweimal auf dieselbe Stelle bewerben
    UNIQUE KEY uq_bewerbung_pro_stelle (bewerberId, stelleId),
    KEY idx_bewerbung_status   (status),
    KEY idx_bewerbung_eingang  (eingangAm),
    CONSTRAINT fk_bewerbung_bewerber
        FOREIGN KEY (bewerberId) REFERENCES bewerber(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bewerbung_stelle
        FOREIGN KEY (stelleId) REFERENCES stellenangebot(id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: dokument
-- Zweck  : Anhaenge zu einer Bewerbung (Lebenslauf, Zeugnis, ...)
CREATE TABLE dokument (
    id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    bewerbungId     INT UNSIGNED   NOT NULL,
    typ             ENUM('LEBENSLAUF','ZEUGNIS','ANSCHREIBEN','ZERTIFIKAT','ARBEITSPROBE','SONSTIGES')
                                   NOT NULL,
    dateiname       VARCHAR(255)   NOT NULL,
    dateigroesse    INT UNSIGNED   NOT NULL,
    mimeType        VARCHAR(120)   NOT NULL,
    gespeichertPfad VARCHAR(500)   NOT NULL,
    hochgeladenAm   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_dokument_bewerbung (bewerbungId),
    KEY idx_dokument_typ       (typ),
    CONSTRAINT fk_dokument_bewerbung
        FOREIGN KEY (bewerbungId) REFERENCES bewerbung(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_dokument_groesse
        CHECK (dateigroesse <= 10485760)        -- max. 10 MiB
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: bewertung
-- Zweck  : Bewertung einer Bewerbung durch HR / Fachbereich
CREATE TABLE bewertung (
    id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    bewerbungId  INT UNSIGNED  NOT NULL,
    hrMaId       INT UNSIGNED  NOT NULL,
    score        TINYINT       NOT NULL,
    kommentar    VARCHAR(1000) NULL,
    empfehlung   ENUM('EINSTELLEN','WEITER_PRUEFEN','ABLEHNEN')
                               NOT NULL,
    datum        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_bewertung_je_reviewer (bewerbungId, hrMaId),
    KEY idx_bewertung_empfehlung (empfehlung),
    CONSTRAINT fk_bewertung_bewerbung
        FOREIGN KEY (bewerbungId) REFERENCES bewerbung(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_bewertung_hr
        FOREIGN KEY (hrMaId) REFERENCES hr_mitarbeiter(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_bewertung_score
        CHECK (score BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: status_history
-- Zweck  : Audit-Spur der Statuswechsel einer Bewerbung
CREATE TABLE status_history (
    id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    bewerbungId  INT UNSIGNED  NOT NULL,
    hrMaId       INT UNSIGNED  NOT NULL,
    alterStatus  VARCHAR(30)   NULL,
    neuerStatus  VARCHAR(30)   NOT NULL,
    geaendertAm  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_status_hist_bewerbung (bewerbungId, geaendertAm),
    KEY idx_status_hist_hr        (hrMaId),
    CONSTRAINT fk_status_hist_bewerbung
        FOREIGN KEY (bewerbungId) REFERENCES bewerbung(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_status_hist_hr
        FOREIGN KEY (hrMaId) REFERENCES hr_mitarbeiter(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_status_hist_wechsel
        CHECK (alterStatus IS NULL OR alterStatus <> neuerStatus)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- Tabelle: einwilligung
-- Zweck  : DSGVO-Einwilligungen der Bewerber:innen (mit Widerruf)
CREATE TABLE einwilligung (
    id           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    bewerberId   INT UNSIGNED  NOT NULL,
    version      VARCHAR(20)   NOT NULL,
    gegebenAm    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    widerrufenAm DATETIME      NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_einwilligung_version (bewerberId, version),
    KEY idx_einwilligung_bewerber (bewerberId),
    CONSTRAINT fk_einwilligung_bewerber
        FOREIGN KEY (bewerberId) REFERENCES bewerber(id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_einwilligung_widerruf
        CHECK (widerrufenAm IS NULL OR widerrufenAm >= gegebenAm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------------
-- 3. Optional: kleine Demo-Daten zum Testen
-- ----------------------------------------------------------------------
INSERT INTO bewerber (vorname, nachname, email, telefon)
VALUES ('Anna', 'Muster', 'anna.muster@example.com', '+49 170 1234567');

INSERT INTO stellenangebot (titel, beschreibung, art, status, veroeffentlichtAm)
VALUES ('Werkstudent:in Backend', 'Spring Boot / MariaDB', 'WERKSTUDENT',
        'VEROEFFENTLICHT', CURRENT_TIMESTAMP);

INSERT INTO hr_mitarbeiter (name, email, rolle)
VALUES ('Sina Recruiter', 'sina.recruiter@example.com', 'RECRUITER');

INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, status)
VALUES (1, 1, 'BW-2026-0001', 'EINGEGANGEN');

INSERT INTO dokument (bewerbungId, typ, dateiname, dateigroesse, mimeType, gespeichertPfad)
VALUES (1, 'LEBENSLAUF', 'lebenslauf_muster.pdf', 245760, 'application/pdf',
        '/storage/bw/2026/0001/lebenslauf_muster.pdf');

INSERT INTO einwilligung (bewerberId, version)
VALUES (1, '2025-01');

-- =====================================================================
-- Ende init_bewerbung.sql
-- =====================================================================
