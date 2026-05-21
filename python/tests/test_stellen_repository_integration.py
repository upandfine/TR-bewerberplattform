"""INTEGRATION-Test fuer das Stellenangebot-Repository: gegen die
echte MariaDB, jeder Test wird per Rollback abgeraeumt."""

import pytest

import db
from stellen_repository import PyMySQLStellenangebotRepository


@pytest.fixture()
def repo():
    conn = db.connect()
    conn.begin()
    try:
        yield PyMySQLStellenangebotRepository(conn)
    finally:
        conn.rollback()
        conn.close()


def test_stelle_anlegen_liefert_id(repo):
    sid = repo.insert_stelle({
        "titel": "Integration: Backend",
        "beschreibung": "Python/MariaDB",
        "art": "FESTANSTELLUNG",
        "status": "ENTWURF",
    })
    assert sid > 0


def test_liste_filtert_nach_status(repo):
    repo.insert_stelle({
        "titel": "I-A", "beschreibung": None,
        "art": "FESTANSTELLUNG", "status": "ENTWURF",
    })
    repo.insert_stelle({
        "titel": "I-B", "beschreibung": None,
        "art": "WERKSTUDENT", "status": "VEROEFFENTLICHT",
    })

    entwurf = repo.list_stellen("ENTWURF")
    titel = [r["titel"] for r in entwurf]
    assert "I-A" in titel
    assert "I-B" not in titel


def test_prepared_statement_verhindert_sql_injection(repo):
    # Klassischer Injection-Versuch: bei naivem Concat wuerde
    # hier eine zweite Anweisung ausgefuehrt. Da Parameter
    # gebunden werden, ist es nur ein normaler String.
    boese = "Hacker'); DROP TABLE stellenangebot; --"
    sid = repo.insert_stelle({
        "titel": boese, "beschreibung": None,
        "art": "FESTANSTELLUNG", "status": "ENTWURF",
    })

    alle = repo.list_stellen(None)
    titel = [r["titel"] for r in alle]
    assert boese in titel
    assert sid > 0
