// Naht zwischen Stellenangebot-Service und Persistenz.
// Im Unit-Test wird diese Klasse durch ein In-Memory-Fake ersetzt.
//
// Alle SQL-Statements nutzen Prepared Statements (mysql2 `execute`)
// -> Schutz vor SQL-Injection.

class MysqlStellenangebotRepository {
  constructor(conn) {
    this.conn = conn;
  }

  async insertStelle(stelle) {
    const [res] = await this.conn.execute(
      "INSERT INTO stellenangebot (titel, beschreibung, art, status) " +
        "VALUES (?, ?, ?, ?)",
      [stelle.titel, stelle.beschreibung ?? null, stelle.art, stelle.status]
    );
    return Number(res.insertId);
  }

  async listStellen(status) {
    let sql =
      "SELECT id, " +
      "       titel, " +
      "       beschreibung, " +
      "       art, " +
      "       status, " +
      "       erstelltAm        AS erstellt_am, " +
      "       veroeffentlichtAm AS veroeffentlicht_am " +
      "FROM stellenangebot";
    const params = [];
    if (status != null) {
      sql += " WHERE status = ?";
      params.push(status);
    }
    sql += " ORDER BY erstelltAm DESC";

    const [rows] = await this.conn.execute(sql, params);
    return rows;
  }
}

module.exports = { MysqlStellenangebotRepository };
