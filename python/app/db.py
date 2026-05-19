"""Persistenz-Verbindung. Zugangsdaten kommen aus den
Umgebungsvariablen (DB_HOST/DB_NAME/DB_USER/DB_PASS, aus der .env)."""

import os
import pymysql


def connect() -> pymysql.connections.Connection:
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True,
    )
