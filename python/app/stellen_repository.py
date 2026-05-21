"""Naht zwischen Stellenangebot-Service und Persistenz.

`StellenangebotRepository` ist das Protokoll (Interface). Im
Unit-Test wird es durch ein In-Memory-Fake ersetzt -> ohne DB.

Alle SQL-Statements der echten Umsetzung nutzen Prepared Statements
(`cursor.execute(sql, params)`) -> Schutz vor SQL-Injection.
"""

from typing import Protocol


class StellenangebotRepository(Protocol):
    def insert_stelle(self, stelle: dict) -> int: ...

    def list_stellen(self, status: str | None) -> list[dict]: ...


class PyMySQLStellenangebotRepository:
    def __init__(self, conn) -> None:
        self.conn = conn

    def insert_stelle(self, stelle: dict) -> int:
        with self.conn.cursor() as cur:
            cur.execute(
                "INSERT INTO stellenangebot "
                "(titel, beschreibung, art, status) "
                "VALUES (%s, %s, %s, %s)",
                (stelle["titel"], stelle["beschreibung"],
                 stelle["art"], stelle["status"]),
            )
            return int(cur.lastrowid)

    def list_stellen(self, status: str | None) -> list[dict]:
        sql = (
            "SELECT id, "
            "       titel, "
            "       beschreibung, "
            "       art, "
            "       status, "
            "       erstelltAm        AS erstellt_am, "
            "       veroeffentlichtAm AS veroeffentlicht_am "
            "FROM stellenangebot"
        )
        params: tuple = ()
        if status is not None:
            sql += " WHERE status = %s"
            params = (status,)
        sql += " ORDER BY erstelltAm DESC"

        with self.conn.cursor() as cur:
            cur.execute(sql, params)
            return list(cur.fetchall())
