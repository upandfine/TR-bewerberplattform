"""HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.

Endpunkte:
    GET  /                  -> kleiner Health-Check
    POST /api/bewerbungen   -> Bewerbung einreichen
    GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)
"""

import pymysql
from flask import Flask, jsonify, request

import db
from errors import ValidationError
from repository import PyMySQLBewerbungRepository
from service import BewerbungService

app = Flask(__name__)


def _service() -> BewerbungService:
    return BewerbungService(PyMySQLBewerbungRepository(db.connect()))


@app.get("/")
def index():
    return "<h1>Python / Flask läuft</h1><p>API unter /api/bewerbungen</p>"


@app.post("/api/bewerbungen")
def einreichen():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        return jsonify({"fehler": "Body muss gültiges JSON sein."}), 400
    try:
        return jsonify(_service().einreichen(data)), 201
    except ValidationError as e:
        return jsonify({"fehler": str(e), "details": e.errors}), 400
    except pymysql.err.IntegrityError as e:
        code = e.args[0]
        if code == 1452:
            return jsonify({"fehler": "Angegebene stelle_id existiert nicht."}), 422
        if code == 1062:
            return jsonify({"fehler": "Vorgangsnummer-Kollision, bitte erneut senden."}), 409
        return jsonify({"fehler": "Datenbankfehler."}), 500


@app.get("/api/bewerbungen")
def liste():
    status = request.args.get("status")
    return jsonify({"bewerbungen": _service().liste(status)}), 200


if __name__ == "__main__":
    # 0.0.0.0 ist wichtig, damit der Container von außen erreichbar ist
    app.run(host="0.0.0.0", port=8000)
