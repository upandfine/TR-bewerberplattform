"""INTEGRATION-Test gegen die ECHTE MariaDB.
Jeder Test in einer Transaktion, die zurückgerollt wird."""

import pymysql
import pytest

import db
from repository import PyMySQLBewerbungRepository


@pytest.fixture()
def repo():
    conn = db.connect()
    conn.begin()
    try:
        yield PyMySQLBewerbungRepository(conn)
    finally:
        conn.rollback()
        conn.close()


def _eine_stelle_id(conn) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO stellenangebot (titel, art, status) "
            "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')"
        )
        return int(cur.lastrowid)


def test_bewerber_anlegen_und_per_email_finden(repo):
    bid = repo.insert_bewerber({
        "vorname": "Erika", "nachname": "Mustermann",
        "email": "py-int@example.com", "telefon": None,
    })
    assert repo.find_bewerber_id_by_email("py-int@example.com") == bid
    assert repo.find_bewerber_id_by_email("nope@example.com") is None


def test_bewerbung_anlegen_funktioniert(repo):
    stelle_id = _eine_stelle_id(repo.conn)
    bid = repo.insert_bewerber({
        "vorname": "Max", "nachname": "M",
        "email": "py-m@example.com", "telefon": None,
    })
    aid = repo.insert_bewerbung(bid, stelle_id, "BEW-2026-PYAB01", None)
    assert aid > 0


def test_fremdschluessel_verhindert_ungueltige_stelle(repo):
    bid = repo.insert_bewerber({
        "vorname": "A", "nachname": "B",
        "email": "py-fk@example.com", "telefon": None,
    })
    with pytest.raises(pymysql.err.IntegrityError) as ex:
        repo.insert_bewerbung(bid, 999999, "BEW-2026-PYFK01", None)
    assert ex.value.args[0] == 1452


def test_vorgangsnummer_ist_eindeutig(repo):
    stelle_id = _eine_stelle_id(repo.conn)
    bid = repo.insert_bewerber({
        "vorname": "C", "nachname": "D",
        "email": "py-uq@example.com", "telefon": None,
    })
    repo.insert_bewerbung(bid, stelle_id, "BEW-2026-PYDUP1", None)
    with pytest.raises(pymysql.err.IntegrityError) as ex:
        repo.insert_bewerbung(bid, stelle_id, "BEW-2026-PYDUP1", None)
    assert ex.value.args[0] == 1062
