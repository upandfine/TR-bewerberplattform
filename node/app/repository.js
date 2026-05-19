// Naht zwischen Service (reine Logik) und Persistenz.
// Im Unit-Test wird diese Klasse durch ein In-Memory-Fake mit
// denselben Methoden ersetzt -> Service-Tests ohne Datenbank.
//
// Spalten heißen in der DB camelCase; nach außen liefern wir stabile
// snake_case-Schlüssel (gleicher Vertrag wie PHP/Python).

class MysqlBewerbungRepository {
  constructor(conn) {
    this.conn = conn;
  }

  async findBewerberIdByEmail(email) {
    const [rows] = await this.conn.execute(
      "SELECT id FROM bewerber WHERE email = ?",
      [email]
    );
    return rows.length ? Number(rows[0].id) : null;
  }

  async insertBewerber(b) {
    const [res] = await this.conn.execute(
      "INSERT INTO bewerber (vorname, nachname, email, telefon) VALUES (?, ?, ?, ?)",
      [b.vorname, b.nachname, b.email, b.telefon ?? null]
    );
    return Number(res.insertId);
  }

  async insertBewerbung(bewerberId, stelleId, vorgangsNr, bemerkung) {
    const [res] = await this.conn.execute(
      "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) VALUES (?, ?, ?, ?)",
      [bewerberId, stelleId, vorgangsNr, bemerkung ?? null]
    );
    return Number(res.insertId);
  }

  async listBewerbungen(status) {
    let sql =
      "SELECT b.id, " +
      "       b.vorgangsNr AS vorgangs_nr, " +
      "       b.status, " +
      "       b.eingangAm  AS eingang_am, " +
      "       bw.vorname, bw.nachname, bw.email, " +
      "       s.titel AS stelle " +
      "FROM bewerbung b " +
      "JOIN bewerber bw      ON bw.id = b.bewerberId " +
      "JOIN stellenangebot s ON s.id  = b.stelleId";
    const params = [];
    if (status != null) {
      sql += " WHERE b.status = ?";
      params.push(status);
    }
    sql += " ORDER BY b.eingangAm DESC";

    const [rows] = await this.conn.execute(sql, params);
    return rows;
  }
}

module.exports = { MysqlBewerbungRepository };
