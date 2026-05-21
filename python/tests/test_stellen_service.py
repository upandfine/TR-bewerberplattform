"""UNIT-Test fuer StellenangebotService: ohne Datenbank, mit Fake-Repo."""

import pytest

from errors import ValidationError
from stellen_service import StellenangebotService


class FakeStellenRepo:
    def __init__(self) -> None:
        self.rows: list[dict] = []
        self.next_id = 1

    def insert_stelle(self, stelle: dict) -> int:
        i = self.next_id
        self.next_id += 1
        self.rows.append({"id": i, **stelle})
        return i

    def list_stellen(self, status):
        if status is None:
            return list(self.rows)
        return [r for r in self.rows if r["status"] == status]


def test_neue_stelle_startet_immer_als_entwurf():
    repo = FakeStellenRepo()
    svc = StellenangebotService(repo)

    res = svc.anlegen({
        "titel": "Senior Backend",
        "art": "FESTANSTELLUNG",
        # Aufrufer versucht ENTWURF zu umgehen - Service ignoriert das.
        "status": "VEROEFFENTLICHT",
    })

    assert res["status"] == "ENTWURF"
    assert repo.rows[0]["status"] == "ENTWURF"


def test_standard_art_ist_festanstellung():
    svc = StellenangebotService(FakeStellenRepo())
    res = svc.anlegen({"titel": "Praktikant:in"})
    assert res["art"] == "FESTANSTELLUNG"


def test_titel_ist_pflicht():
    svc = StellenangebotService(FakeStellenRepo())
    with pytest.raises(ValidationError):
        svc.anlegen({"titel": "   "})


def test_ungueltige_art_wird_abgelehnt():
    svc = StellenangebotService(FakeStellenRepo())
    with pytest.raises(ValidationError):
        svc.anlegen({"titel": "Stelle", "art": "KEIN_ECHTER_TYP"})


def test_liste_filtert_nach_status():
    repo = FakeStellenRepo()
    svc = StellenangebotService(repo)

    svc.anlegen({"titel": "A"})
    svc.anlegen({"titel": "B"})
    repo.insert_stelle({
        "titel": "C", "beschreibung": None,
        "art": "FESTANSTELLUNG", "status": "VEROEFFENTLICHT",
    })

    entwuerfe = svc.liste("ENTWURF")
    assert len(entwuerfe) == 2


def test_liste_mit_ungueltigem_status_wirft():
    svc = StellenangebotService(FakeStellenRepo())
    with pytest.raises(ValidationError):
        svc.liste("UNBEKANNT")
