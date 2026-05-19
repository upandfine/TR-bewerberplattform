"""UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository)."""

import re

import pytest

from errors import ValidationError
from service import BewerbungService


class FakeRepo:
    def __init__(self) -> None:
        self.emails: dict[str, int] = {}
        self.next_id = 1

    def find_bewerber_id_by_email(self, email):
        return self.emails.get(email)

    def insert_bewerber(self, bewerber):
        i = self.next_id
        self.next_id += 1
        self.emails[bewerber["email"]] = i
        return i

    def insert_bewerbung(self, bewerber_id, stelle_id, vorgangs_nr, bemerkung):
        i = self.next_id
        self.next_id += 1
        return i

    def list_bewerbungen(self, status):
        return []


def test_einreichen_liefert_vorgangsnummer_im_format():
    svc = BewerbungService(FakeRepo())
    res = svc.einreichen({
        "vorname": "Erika", "nachname": "Mustermann",
        "email": "erika@example.com", "stelle_id": 1,
    })
    assert re.match(r"^BEW-\d{4}-[0-9A-F]{6}$", res["vorgangs_nr"])
    assert isinstance(res["bewerbung_id"], int)


def test_bekannte_email_wird_wiederverwendet():
    repo = FakeRepo()
    svc = BewerbungService(repo)
    a = svc.einreichen({"vorname": "Max", "nachname": "M",
                         "email": "max@example.com", "stelle_id": 1})
    b = svc.einreichen({"vorname": "Max", "nachname": "M",
                         "email": "max@example.com", "stelle_id": 2})
    assert a["bewerber_id"] == b["bewerber_id"]


def test_fehlende_pflichtfelder_werfen_validation_error():
    svc = BewerbungService(FakeRepo())
    with pytest.raises(ValidationError) as ex:
        svc.einreichen({"email": "kaputt", "stelle_id": 0})
    assert len(ex.value.errors) >= 3


def test_generate_vorgangs_nr_format():
    assert re.match(r"^BEW-\d{4}-[0-9A-F]{6}$",
                    BewerbungService.generate_vorgangs_nr())
