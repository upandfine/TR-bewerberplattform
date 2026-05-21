"""API-/E2E-Test fuer /api_stellen: echter HTTP-Durchstich gegen
http://localhost:8000."""

import json
import urllib.error
import urllib.request
import uuid

import pytest

import db

BASE = "http://localhost:8000/api_stellen"


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
def titel():
    t = f"APITest-{uuid.uuid4().hex}"
    yield t
    conn = db.connect()
    with conn.cursor() as cur:
        cur.execute("DELETE FROM stellenangebot WHERE titel = %s", (t,))
    conn.close()


def test_post_legt_stelle_mit_status_entwurf_an(titel):
    status, post = _request("POST", BASE, {
        "titel": titel,
        "art": "WERKSTUDENT",
        # Versucht ENTWURF zu umgehen - Service-Regel verhindert das.
        "status": "VEROEFFENTLICHT",
    })

    assert status == 201
    assert post["status"] == "ENTWURF"
    assert post["art"] == "WERKSTUDENT"
    assert isinstance(post["id"], int)


def test_get_listet_die_angelegte_stelle(titel):
    _request("POST", BASE, {"titel": titel, "art": "PRAKTIKUM"})

    status, get = _request("GET", BASE + "?status=ENTWURF")
    assert status == 200
    titel_liste = [s["titel"] for s in get["stellen"]]
    assert titel in titel_liste


def test_post_ohne_titel_liefert_400(titel):
    status, body = _request("POST", BASE, {"art": "AZUBI"})
    assert status == 400
    assert "details" in body
