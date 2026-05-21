package de.train.bewerbung

import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.sql.Connection
import java.sql.SQLException
import java.sql.Statement

/**
 * INTEGRATION-Test gegen die ECHTE MariaDB.
 * Jeder Test in einer Transaktion, die zurueckgerollt wird.
 */
class JdbcBewerbungRepositoryTest {

    private lateinit var conn: Connection
    private lateinit var repo: JdbcBewerbungRepository

    @BeforeEach
    fun setUp() {
        conn = openConnection()
        conn.autoCommit = false
        repo = JdbcBewerbungRepository(conn)
    }

    @AfterEach
    fun tearDown() {
        conn.rollback()
        conn.close()
    }

    private fun eineStelleId(): Int {
        conn.createStatement().use { st ->
            st.executeUpdate(
                "INSERT INTO stellenangebot (titel, art, status) " +
                        "VALUES ('Test-Stelle', 'FESTANSTELLUNG', 'VEROEFFENTLICHT')",
                Statement.RETURN_GENERATED_KEYS
            )
            st.generatedKeys.use { rs -> rs.next(); return rs.getInt(1) }
        }
    }

    @Test
    fun `bewerber anlegen und per email finden`() {
        val id = repo.insertBewerber(BewerberInput(
            "Erika", "Mustermann", "kt-int@example.com", null))
        assertEquals(id, repo.findBewerberIdByEmail("kt-int@example.com"))
        assertNull(repo.findBewerberIdByEmail("unbekannt@example.com"))
    }

    @Test
    fun `bewerbung anlegen funktioniert`() {
        val stelleId = eineStelleId()
        val bid = repo.insertBewerber(BewerberInput("Max", "M", "kt-m@example.com", null))
        val id = repo.insertBewerbung(bid, stelleId, "BEW-2026-KTLN01", null)
        assertTrue(id > 0)
    }

    @Test
    fun `fk verhindert ungueltige stelle`() {
        val bid = repo.insertBewerber(BewerberInput("A", "B", "kt-fk@example.com", null))
        val ex = assertThrows(SQLException::class.java) {
            repo.insertBewerbung(bid, 999999, "BEW-2026-KTFK01", null)
        }
        assertEquals(1452, ex.errorCode)
    }

    @Test
    fun `vorgangsnummer ist eindeutig`() {
        val stelleId = eineStelleId()
        val bid = repo.insertBewerber(BewerberInput("C", "D", "kt-uq@example.com", null))
        repo.insertBewerbung(bid, stelleId, "BEW-2026-KTDUP1", null)
        val ex = assertThrows(SQLException::class.java) {
            repo.insertBewerbung(bid, stelleId, "BEW-2026-KTDUP1", null)
        }
        assertEquals(1062, ex.errorCode)
    }
}
