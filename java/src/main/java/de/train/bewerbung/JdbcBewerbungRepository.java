package de.train.bewerbung;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Konkrete Persistenz gegen MariaDB. Integration-testbar gegen die
 * laufende DB (FK-RESTRICT auf Stelle, UNIQUE vorgangsNr).
 *
 * Spalten in der DB sind camelCase; nach aussen liefern wir stabile
 * snake_case-Schluessel (gleicher Vertrag wie PHP/Python/Node/.NET).
 */
public final class JdbcBewerbungRepository implements BewerbungRepository {

    private final Connection conn;

    public JdbcBewerbungRepository(Connection conn) {
        this.conn = conn;
    }

    @Override
    public Integer findBewerberIdByEmail(String email) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT id FROM bewerber WHERE email = ?")) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    @Override
    public int insertBewerber(BewerberInput b) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO bewerber (vorname, nachname, email, telefon) "
                        + "VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, b.vorname());
            ps.setString(2, b.nachname());
            ps.setString(3, b.email());
            if (b.telefon() == null) {
                ps.setNull(4, java.sql.Types.VARCHAR);
            } else {
                ps.setString(4, b.telefon());
            }
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    @Override
    public int insertBewerbung(int bewerberId, int stelleId, String vorgangsNr, String bemerkung)
            throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO bewerbung (bewerberId, stelleId, vorgangsNr, bemerkung) "
                        + "VALUES (?, ?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, bewerberId);
            ps.setInt(2, stelleId);
            ps.setString(3, vorgangsNr);
            if (bemerkung == null) {
                ps.setNull(4, java.sql.Types.VARCHAR);
            } else {
                ps.setString(4, bemerkung);
            }
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    @Override
    public List<Map<String, Object>> listBewerbungen(String status) throws SQLException {
        String sql =
                "SELECT b.id, "
                        + "       b.vorgangsNr AS vorgangs_nr, "
                        + "       b.status, "
                        + "       b.eingangAm  AS eingang_am, "
                        + "       bw.vorname, bw.nachname, bw.email, "
                        + "       s.titel AS stelle "
                        + "FROM bewerbung b "
                        + "JOIN bewerber bw      ON bw.id = b.bewerberId "
                        + "JOIN stellenangebot s ON s.id  = b.stelleId";
        if (status != null) {
            sql += " WHERE b.status = ?";
        }
        sql += " ORDER BY b.eingangAm DESC";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            if (status != null) {
                ps.setString(1, status);
            }
            try (ResultSet rs = ps.executeQuery()) {
                List<Map<String, Object>> rows = new ArrayList<>();
                int n = rs.getMetaData().getColumnCount();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= n; i++) {
                        Object v = rs.getObject(i);
                        if (v instanceof java.sql.Timestamp ts) {
                            v = ts.toLocalDateTime().toString().replace('T', ' ');
                        }
                        row.put(rs.getMetaData().getColumnLabel(i), v);
                    }
                    rows.add(row);
                }
                return rows;
            }
        }
    }
}
