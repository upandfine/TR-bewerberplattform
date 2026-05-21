# Naht zwischen Service (reine Logik) und Persistenz.
#
# Im Unit-Test wird diese Klasse durch ein In-Memory-Fake mit
# denselben Methoden ersetzt (Duck Typing) -> Service-Tests ohne
# Datenbank.
#
# Spalten heissen in der DB camelCase; nach aussen liefern wir
# stabile snake_case-Schluessel (gleicher Vertrag wie PHP/Python/
# Node/.NET/Java/Kotlin/Go).
class MysqlBewerbungRepository
  def initialize(conn)
    @conn = conn
  end

  def find_bewerber_id_by_email(email)
    stmt = @conn.prepare("SELECT id FROM bewerber WHERE email = ?")
    result = stmt.execute(email)
    row = result.first
    row ? row["id"].to_i : nil
  ensure
    stmt&.close
  end

  def insert_bewerber(bewerber)
    stmt = @conn.prepare(
      "INSERT INTO bewerber (vorname, nachname, email, telefon) VALUES (?, ?, ?, ?)"
    )
    stmt.execute(
      bewerber[:vorname],
      bewerber[:nachname],
      bewerber[:email],
      bewerber[:telefon],
    )
    @conn.last_id
  ensure
    stmt&.close
  end

  def insert_bewerbung(bewerber_id, stelle_id, vorgangs_nr, bemerkung)
    stmt = @conn.prepare(
      "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) VALUES (?, ?, ?, ?)"
    )
    stmt.execute(bewerber_id, stelle_id, vorgangs_nr, bemerkung)
    @conn.last_id
  ensure
    stmt&.close
  end

  def list_bewerbungen(status)
    sql = <<~SQL.strip
      SELECT b.id,
             b.vorgangsNr AS vorgangs_nr,
             b.status,
             b.eingangAm  AS eingang_am,
             bw.vorname, bw.nachname, bw.email,
             s.titel AS stelle
      FROM bewerbung b
      JOIN bewerber bw      ON bw.id = b.bewerberId
      JOIN stellenangebot s ON s.id  = b.stelleId
    SQL
    sql += " WHERE b.status = ?" unless status.nil?
    sql += " ORDER BY b.eingangAm DESC"

    stmt = @conn.prepare(sql)
    result = status.nil? ? stmt.execute : stmt.execute(status)
    rows = result.to_a
    # eingang_am als String fuer JSON serialisieren (DateTime -> "YYYY-MM-DD HH:MM:SS")
    rows.each do |row|
      row.each do |k, v|
        row[k] = v.strftime("%Y-%m-%d %H:%M:%S") if v.is_a?(Time)
      end
    end
    rows
  ensure
    stmt&.close
  end
end
