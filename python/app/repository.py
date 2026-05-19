"""Naht zwischen Service (reine Logik) und Persistenz.

`BewerbungRepository` ist das Protokoll (Interface). Im Unit-Test
wird es durch ein In-Memory-Fake ersetzt -> ohne Datenbank.
`PyMySQLBewerbungRepository` ist die echte Umsetzung gegen MariaDB.

Spalten heißen in der DB camelCase; nach außen liefern wir stabile
snake_case-Schlüssel (gleicher Vertrag wie die PHP-Variante).
"""

from typing import Protocol


class BewerbungRepository(Protocol):
    def find_bewerber_id_by_email(self, email: str) -> int | None: ...

    def insert_bewerber(self, bewerber: dict) -> int: ...

    def insert_bewerbung(
        self, bewerber_id: int, stelle_id: int,
        vorgangs_nr: str, bemerkung: str | None
    ) -> int: ...

    def list_bewerbungen(self, status: str | None) -> list[dict]: ...


class PyMySQLBewerbungRepository:
    def __init__(self, conn) -> None:
        self.conn = conn

    def find_bewerber_id_by_email(self, email: str) -> int | None:
        with self.conn.cursor() as cur:
            cur.execute("SELECT id FROM bewerber WHERE email = %s", (email,))
            row = cur.fetchone()
        return int(row["id"]) if row else None

    def insert_bewerber(self, bewerber: dict) -> int:
        with self.conn.cursor() as cur:
            cur.execute(
                "INSERT INTO bewerber (vorname, nachname, email, telefon) "
                "VALUES (%s, %s, %s, %s)",
                (bewerber["vorname"], bewerber["nachname"],
                 bewerber["email"], bewerber.get("telefon")),
            )
            return int(cur.lastrowid)

    def insert_bewerbung(
        self, bewerber_id: int, stelle_id: int,
        vorgangs_nr: str, bemerkung: str | None
    ) -> int:
        with self.conn.cursor() as cur:
            cur.execute(
                "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) "
                "VALUES (%s, %s, %s, %s)",
                (bewerber_id, stelle_id, vorgangs_nr, bemerkung),
            )
            return int(cur.lastrowid)

    def list_bewerbungen(self, status: str | None) -> list[dict]:
        sql = (
            "SELECT b.id, "
            "       b.vorgangsNr AS vorgangs_nr, "
            "       b.status, "
            "       b.eingangAm  AS eingang_am, "
            "       bw.vorname, bw.nachname, bw.email, "
            "       s.titel AS stelle "
            "FROM bewerbung b "
            "JOIN bewerber bw      ON bw.id = b.bewerberId "
            "JOIN stellenangebot s ON s.id  = b.stelleId"
        )
        params: tuple = ()
        if status is not None:
            sql += " WHERE b.status = %s"
            params = (status,)
        sql += " ORDER BY b.eingangAm DESC"

        with self.conn.cursor() as cur:
            cur.execute(sql, params)
            return list(cur.fetchall())
