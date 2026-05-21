package de.train.bewerbung;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * INTEGRATION-Test: laeuft gegen die ECHTE MariaDB.
 * Jeder Test in einer Transaktion, die am Ende zurueckgerollt
 * wird -> die Datenbank bleibt unveraendert.
 */
class JdbcBewerbungRepositoryTest {

    private Connection conn;
    private JdbcBewerbungRepository repo;

    private static Connection connect() throws SQLException {
        String host = System.getenv("DB_HOST");
        String name = System.getenv("DB_NAME");
        String user = System.getenv("DB_USER");
        String pass = System.getenv("DB_PASS");
        String url = "jdbc:mariadb://" + host + ":3306/" + name
                + "?useUnicode=true&characterEncoding=utf8";
        return DriverManager.getConnection(url, user, pass);
    }

    @BeforeEach
    void setUp() throws SQLException {
        conn = connect();
        conn.setAutoCommit(false);
        repo = new JdbcBewerbungRepository(conn);
    }

    @AfterEach
    void tearDown() throws SQLException {
        if (conn != null) {
            conn.rollback();
            conn.close();
        }
    }

    private int eineStelleId() throws SQLException {
        try (Statement st = conn.createStatement()) {
            st.executeUpdate(
                    "INSERT INTO stellenangebot (titel, art, status) "
                            + "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')",
                    Statement.RETURN_GENERATED_KEYS);
            try (var keys = st.getGeneratedKeys()) {
                keys.next();
                return keys.getInt(1);
            }
        }
    }

    @Test
    void bewerberAnlegenUndPerEmailFinden() throws SQLException {
        int id = repo.insertBewerber(new BewerberInput(
                "Erika", "Mustermann", "java-int@example.com", null));
        assertEquals(Integer.valueOf(id),
                repo.findBewerberIdByEmail("java-int@example.com"));
        assertNull(repo.findBewerberIdByEmail("unbekannt@example.com"));
    }

    @Test
    void bewerbungAnlegenFunktioniert() throws SQLException {
        int stelleId = eineStelleId();
        int bid = repo.insertBewerber(new BewerberInput(
                "Max", "M", "java-m@example.com", null));
        int id = repo.insertBewerbung(bid, stelleId, "BEW-2026-JAVA01", null);
        assertTrue(id > 0);
    }

    @Test
    void fremdschluesselVerhindertUngueltigeStelle() throws SQLException {
        int bid = repo.insertBewerber(new BewerberInput(
                "A", "B", "java-fk@example.com", null));
        SQLException ex = assertThrows(SQLException.class,
                () -> repo.insertBewerbung(bid, 999999, "BEW-2026-JAVAFK", null));
        assertEquals(1452, ex.getErrorCode());
    }

    @Test
    void vorgangsnummerIstEindeutig() throws SQLException {
        int stelleId = eineStelleId();
        int bid = repo.insertBewerber(new BewerberInput(
                "C", "D", "java-uq@example.com", null));
        repo.insertBewerbung(bid, stelleId, "BEW-2026-JADUP1", null);
        SQLException ex = assertThrows(SQLException.class,
                () -> repo.insertBewerbung(bid, stelleId, "BEW-2026-JADUP1", null));
        assertEquals(1062, ex.getErrorCode());
    }
}
