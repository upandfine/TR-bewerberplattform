-- ============================================================
--  Bewerbermanagement - vollständiges Datenmodell (DDL)
--  Quelle: Musterloesung_Bewerbermanagement.docx, Abschnitt 5
--
--  Zielsystem : MariaDB 11
--  Normalform : 3. Normalform (3NF)
--  Ausführen  : ./run-sql.sh sql/scripts/bewerbermanagement.sql
--
--  3NF-Begründung (siehe Musterlösung):
--   - 1NF: alle Attribute atomar, keine Wiederholgruppen
--          (Dokumente, Bewertungen, Statuswechsel = eigene Tabellen).
--   - 2NF: keine Tabelle hat einen zusammengesetzten Schlüssel mit
--          partiell abhängigen Attributen (überall künstlicher PK 'id').
--   - 3NF: keine transitiven Abhängigkeiten. Adressdaten liegen NUR
--          beim Bewerber, nicht dupliziert in der Bewerbung. Die
--          Bewertung kennt die Stelle nur transitiv über die
--          Bewerbung (Bewerbung -> Stellenangebot), nicht direkt.
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- In Abhängigkeitsreihenfolge entfernen, damit das Skript
-- beliebig oft wiederholbar ist (idempotent).
DROP TABLE IF EXISTS status_history;
DROP TABLE IF EXISTS bewertung;
DROP TABLE IF EXISTS dokument;
DROP TABLE IF EXISTS einwilligung;
DROP TABLE IF EXISTS bewerbung;
DROP TABLE IF EXISTS stellenangebot;
DROP TABLE IF EXISTS hr_mitarbeiter;
DROP TABLE IF EXISTS bewerber;

SET FOREIGN_KEY_CHECKS = 1;


-- ------------------------------------------------------------
--  Bewerber:in
--  Adressdaten gehören ausschließlich hierher (3NF).
-- ------------------------------------------------------------
CREATE TABLE bewerber (
    id           INT          NOT NULL AUTO_INCREMENT,
    vorname      VARCHAR(100) NOT NULL,
    nachname     VARCHAR(100) NOT NULL,
    email        VARCHAR(190) NOT NULL,
    telefon      VARCHAR(40)      NULL,
    geburtsdatum DATE             NULL,
    strasse      VARCHAR(150)     NULL,
    hausnummer   VARCHAR(20)      NULL,
    plz          VARCHAR(10)      NULL,
    ort          VARCHAR(100)     NULL,
    land         VARCHAR(80)      NULL DEFAULT 'Deutschland',
    erstellt_am  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bewerber PRIMARY KEY (id),
    CONSTRAINT uq_bewerber_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
--  HR-Mitarbeiter:in (interne Bearbeiter:innen)
--  Rollenmodell laut Musterlösung (Bewerber:in ist KEINE
--  HR-Rolle und daher hier nicht enthalten).
-- ------------------------------------------------------------
CREATE TABLE hr_mitarbeiter (
    id          INT          NOT NULL AUTO_INCREMENT,
    name        VARCHAR(150) NOT NULL,
    email       VARCHAR(190) NOT NULL,
    rolle       ENUM('HR_MITARBEITER','HR_LEITUNG','FACHABTEILUNG')
                             NOT NULL DEFAULT 'HR_MITARBEITER',
    aktiv       BOOLEAN      NOT NULL DEFAULT TRUE,
    erstellt_am TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_hr_mitarbeiter PRIMARY KEY (id),
    CONSTRAINT uq_hr_mitarbeiter_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
--  Stellenangebot
-- ------------------------------------------------------------
CREATE TABLE stellenangebot (
    id               INT          NOT NULL AUTO_INCREMENT,
    titel            VARCHAR(150) NOT NULL,
    beschreibung     TEXT             NULL,
    art              ENUM('FESTANSTELLUNG','AZUBI','MINIJOB',
                          'WERKSTUDENT','PRAKTIKUM')
                                  NOT NULL,
    status           ENUM('ENTWURF','VEROEFFENTLICHT','ARCHIVIERT')
                                  NOT NULL DEFAULT 'ENTWURF',
    erstellt_am      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    veroeffentlicht_am TIMESTAMP      NULL,
    CONSTRAINT pk_stellenangebot PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_stellenangebot_status ON stellenangebot (status);


-- ------------------------------------------------------------
--  Bewerbung  (Bewerber:in 1 - n  /  Stellenangebot 1 - n)
--  Statuswerte = erlaubte Übergänge laut Anforderung F4.
-- ------------------------------------------------------------
CREATE TABLE bewerbung (
    id          INT          NOT NULL AUTO_INCREMENT,
    bewerber_id INT          NOT NULL,
    stelle_id   INT          NOT NULL,
    vorgangs_nr VARCHAR(30)  NOT NULL,
    status      ENUM('EINGEGANGEN','IN_PRUEFUNG','BEWERTET',
                     'EINGELADEN','ZUGESAGT','ABGESAGT')
                             NOT NULL DEFAULT 'EINGEGANGEN',
    bemerkung   TEXT             NULL,
    eingang_am  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bewerbung PRIMARY KEY (id),
    CONSTRAINT uq_bewerbung_vorgangs_nr UNIQUE (vorgangs_nr),
    CONSTRAINT fk_bewerbung_bewerber
        FOREIGN KEY (bewerber_id) REFERENCES bewerber (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bewerbung_stelle
        FOREIGN KEY (stelle_id) REFERENCES stellenangebot (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_bewerbung_status ON bewerbung (status);
CREATE INDEX idx_bewerbung_eingang ON bewerbung (eingang_am);


-- ------------------------------------------------------------
--  Dokument  (Bewerbung 1 - n)
--  Dateigröße laut Anforderung F3 / N2 auf 10 MB begrenzt.
-- ------------------------------------------------------------
CREATE TABLE dokument (
    id               INT          NOT NULL AUTO_INCREMENT,
    bewerbung_id     INT          NOT NULL,
    typ              ENUM('LEBENSLAUF','ZEUGNIS','ANSCHREIBEN','SONSTIGES')
                                  NOT NULL,
    dateiname        VARCHAR(255) NOT NULL,
    dateigroesse     INT          NOT NULL,
    mime_type        VARCHAR(100) NOT NULL,
    gespeichert_pfad VARCHAR(500) NOT NULL,
    hochgeladen_am   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_dokument PRIMARY KEY (id),
    CONSTRAINT fk_dokument_bewerbung
        FOREIGN KEY (bewerbung_id) REFERENCES bewerbung (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_dokument_groesse
        CHECK (dateigroesse > 0 AND dateigroesse <= 10485760)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
--  Bewertung  (Bewerbung 1 - n  /  HR_Mitarbeiter 1 - n)
--  Mehrere Bewertungen pro Bewerbung = 4-Augen-Prinzip (F14).
-- ------------------------------------------------------------
CREATE TABLE bewertung (
    id           INT          NOT NULL AUTO_INCREMENT,
    bewerbung_id INT          NOT NULL,
    hr_ma_id     INT          NOT NULL,
    score        TINYINT      NOT NULL,
    kommentar    TEXT             NULL,
    empfehlung   ENUM('EINLADEN','ABLEHNEN','HALTEN') NOT NULL,
    datum        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bewertung PRIMARY KEY (id),
    CONSTRAINT fk_bewertung_bewerbung
        FOREIGN KEY (bewerbung_id) REFERENCES bewerbung (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bewertung_hr_ma
        FOREIGN KEY (hr_ma_id) REFERENCES hr_mitarbeiter (id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_bewertung_score CHECK (score BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
--  Status_History  (Audit-Trail aller Statuswechsel, Bewerbung 1 - n)
-- ------------------------------------------------------------
CREATE TABLE status_history (
    id            INT       NOT NULL AUTO_INCREMENT,
    bewerbung_id  INT       NOT NULL,
    geaendert_von INT       NOT NULL,
    alter_status  ENUM('EINGEGANGEN','IN_PRUEFUNG','BEWERTET',
                       'EINGELADEN','ZUGESAGT','ABGESAGT')     NULL,
    neuer_status  ENUM('EINGEGANGEN','IN_PRUEFUNG','BEWERTET',
                       'EINGELADEN','ZUGESAGT','ABGESAGT') NOT NULL,
    geaendert_am  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_status_history PRIMARY KEY (id),
    CONSTRAINT fk_status_history_bewerbung
        FOREIGN KEY (bewerbung_id) REFERENCES bewerbung (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_status_history_hr_ma
        FOREIGN KEY (geaendert_von) REFERENCES hr_mitarbeiter (id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_status_history_bewerbung ON status_history (bewerbung_id);


-- ------------------------------------------------------------
--  Einwilligung  (Versionierung über die Zeit, Bewerber:in 1 - n)
--  widerrufen_am NULL = Einwilligung noch gültig.
-- ------------------------------------------------------------
CREATE TABLE einwilligung (
    id            INT          NOT NULL AUTO_INCREMENT,
    bewerber_id   INT          NOT NULL,
    version       VARCHAR(20)  NOT NULL,
    gegeben_am    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    widerrufen_am TIMESTAMP        NULL,
    CONSTRAINT pk_einwilligung PRIMARY KEY (id),
    CONSTRAINT fk_einwilligung_bewerber
        FOREIGN KEY (bewerber_id) REFERENCES bewerber (id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ------------------------------------------------------------
--  Kontrolle: alle Tabellen anzeigen
-- ------------------------------------------------------------
SHOW TABLES;
