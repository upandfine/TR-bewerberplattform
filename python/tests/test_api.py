"""API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
(Flask -> Service -> Repository -> MariaDB), im Container gegen
http://localhost:8000."""

import json
import urllib.error
import urllib.request
import uuid

import pytest

import db

BASE = "http://localhost:8000/api/bewerbungen"


def _request(method: str, url: str, body: dict | None = None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        url, data=data, method=method,
        headers={"Content-Type": "application/json"},
    )
    try:
        resp = urllib.request.urlopen(req)
        return resp.status, json.loads(resp.read() or "null")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or "null")


@pytest.fixture()
def email():
    addr = f"pyapi+{uuid.uuid4().hex}@example.com"
    yield addr
    # ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber löschen
    conn = db.connect()
    with conn.cursor() as cur:
        cur.execute(
            "DELETE FROM bewerbung WHERE bewerberId IN "
            "(SELECT id FROM bewerber WHERE email = %s)", (addr,))
        cur.execute("DELETE FROM bewerber WHERE email = %s", (addr,))
    conn.close()


def _stelle_id() -> int:
    conn = db.connect()
    with conn.cursor() as cur:
        cur.execute("SELECT MIN(id) AS m FROM stellenangebot")
        row = cur.fetchone()
    conn.close()
    if not row or row["m"] is None:
        pytest.skip("Keine Stelle vorhanden - DB neu initialisieren.")
    return int(row["m"])


def test_post_legt_an_und_get_listet(email):
    status, post = _request("POST", BASE, {
        "vorname": "API", "nachname": "Tester",
        "email": email, "stelle_id": _stelle_id(),
    })
    assert status == 201
    assert "vorgangs_nr" in post

    status, get = _request("GET", BASE)
    assert status == 200
    nummern = [b["vorgangs_nr"] for b in get["bewerbungen"]]
    assert post["vorgangs_nr"] in nummern


def test_post_mit_ungueltigen_daten_400(email):
    status, body = _request("POST", BASE, {"email": "kaputt", "stelle_id": 0})
    assert status == 400
    assert "details" in body
