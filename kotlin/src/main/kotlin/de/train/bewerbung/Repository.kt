package de.train.bewerbung

import java.sql.Connection
import java.sql.Statement
import java.sql.Timestamp

/**
 * Naht zwischen Service (reine Logik) und Persistenz.
 * Im Unit-Test wird diese Schnittstelle durch ein In-Memory-Fake
 * ersetzt -> Service-Tests brauchen keine Datenbank.
 */
interface BewerbungRepository {
    fun findBewerberIdByEmail(email: String): Int?
    fun insertBewerber(b: BewerberInput): Int
    fun insertBewerbung(bewerberId: Int, stelleId: Int, vorgangsNr: String, bemerkung: String?): Int
    fun listBewerbungen(status: String?): List<Map<String, Any?>>
}

/**
 * Konkrete Persistenz gegen MariaDB. Integration-testbar gegen die
 * laufende DB (FK-RESTRICT auf Stelle, UNIQUE vorgangsNr).
 *
 * Spalten in der DB sind camelCase; nach aussen liefern wir stabile
 * snake_case-Schluessel (gleicher Vertrag wie PHP/Python/Node/.NET).
 */
class JdbcBewerbungRepository(private val conn: Connection) : BewerbungRepository {

    override fun findBewerberIdByEmail(email: String): Int? {
        conn.prepareStatement("SELECT id FROM bewerber WHERE email = ?").use { ps ->
            ps.setString(1, email)
            ps.executeQuery().use { rs ->
                return if (rs.next()) rs.getInt(1) else null
            }
        }
    }

    override fun insertBewerber(b: BewerberInput): Int {
        conn.prepareStatement(
            "INSERT INTO bewerber (vorname, nachname, email, telefon) VALUES (?, ?, ?, ?)",
            Statement.RETURN_GENERATED_KEYS
        ).use { ps ->
            ps.setString(1, b.vorname)
            ps.setString(2, b.nachname)
            ps.setString(3, b.email)
            if (b.telefon == null) ps.setNull(4, java.sql.Types.VARCHAR) else ps.setString(4, b.telefon)
            ps.executeUpdate()
            ps.generatedKeys.use { rs -> rs.next(); return rs.getInt(1) }
        }
    }

    override fun insertBewerbung(
        bewerberId: Int, stelleId: Int, vorgangsNr: String, bemerkung: String?
    ): Int {
        conn.prepareStatement(
            "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) VALUES (?, ?, ?, ?)",
            Statement.RETURN_GENERATED_KEYS
        ).use { ps ->
            ps.setInt(1, bewerberId)
            ps.setInt(2, stelleId)
            ps.setString(3, vorgangsNr)
            if (bemerkung == null) ps.setNull(4, java.sql.Types.VARCHAR) else ps.setString(4, bemerkung)
            ps.executeUpdate()
            ps.generatedKeys.use { rs -> rs.next(); return rs.getInt(1) }
        }
    }

    override fun listBewerbungen(status: String?): List<Map<String, Any?>> {
        var sql = """
            SELECT b.id,
                   b.vorgangsNr AS vorgangs_nr,
                   b.status,
                   b.eingangAm  AS eingang_am,
                   bw.vorname, bw.nachname, bw.email,
                   s.titel AS stelle
            FROM bewerbung b
            JOIN bewerber bw      ON bw.id = b.bewerberId
            JOIN stellenangebot s ON s.id  = b.stelleId
        """.trimIndent()
        if (status != null) sql += " WHERE b.status = ?"
        sql += " ORDER BY b.eingangAm DESC"

        conn.prepareStatement(sql).use { ps ->
            if (status != null) ps.setString(1, status)
            ps.executeQuery().use { rs ->
                val out = mutableListOf<Map<String, Any?>>()
                val md = rs.metaData
                while (rs.next()) {
                    val row = linkedMapOf<String, Any?>()
                    for (i in 1..md.columnCount) {
                        var v: Any? = rs.getObject(i)
                        if (v is Timestamp) v = v.toLocalDateTime().toString().replace('T', ' ')
                        row[md.getColumnLabel(i)] = v
                    }
                    out.add(row)
                }
                return out
            }
        }
    }
}
