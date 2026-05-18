# ============================================================
#  Demo-App: zeigt, dass Python/Flask läuft und die DB
#  erreichbar ist. Eigenen Code hier erweitern.
#  Änderungen werden nach "docker compose restart python"
#  übernommen.
# ============================================================

import os
from flask import Flask
import pymysql

app = Flask(__name__)


def db_status():
    try:
        conn = pymysql.connect(
            host=os.environ["DB_HOST"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASS"],
            database=os.environ["DB_NAME"],
        )
        with conn.cursor() as cur:
            cur.execute("SELECT VERSION()")
            version = cur.fetchone()[0]
        conn.close()
        return f'<p style="color:green">Datenbank-Verbindung OK - MariaDB {version}</p>'
    except Exception as e:
        return f'<p style="color:red">Keine DB-Verbindung: {e}</p>'


@app.route("/")
def index():
    return f"<h1>Python / Flask läuft </h1>{db_status()}"


if __name__ == "__main__":
    # 0.0.0.0 ist wichtig, damit der Container von außen erreichbar ist
    app.run(host="0.0.0.0", port=8000, debug=True)
