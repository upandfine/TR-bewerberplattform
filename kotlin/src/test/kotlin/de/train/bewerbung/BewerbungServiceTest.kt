package de.train.bewerbung

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertThrows
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * UNIT-Test: reine Fachlogik OHNE Datenbank (Fake-Repository).
 */
class BewerbungServiceTest {

    private class FakeRepo : BewerbungRepository {
        val emails = mutableMapOf<String, Int>()
        var nextId = 1

        override fun findBewerberIdByEmail(email: String): Int? = emails[email]
        override fun insertBewerber(b: BewerberInput): Int {
            val id = nextId++; emails[b.email] = id; return id
        }
        override fun insertBewerbung(
            bewerberId: Int, stelleId: Int, vorgangsNr: String, bemerkung: String?
        ): Int = nextId++
        override fun listBewerbungen(status: String?) = emptyList<Map<String, Any?>>()
    }

    @Test
    fun `einreichen liefert Vorgangsnummer im Format`() {
        val svc = BewerbungService(FakeRepo())
        val r = svc.einreichen(BewerbungInput(
            vorname = "Erika", nachname = "Mustermann",
            email = "erika@example.com", stelleId = 1))
        assertTrue(Regex("^BEW-\\d{4}-[0-9A-F]{6}$").matches(r.vorgangsNr),
            "vorgangs_nr passt nicht: ${r.vorgangsNr}")
        assertTrue(r.bewerbungId > 0)
    }

    @Test
    fun `bekannte E-Mail wird wiederverwendet`() {
        val svc = BewerbungService(FakeRepo())
        val a = svc.einreichen(BewerbungInput(
            vorname = "Max", nachname = "M",
            email = "max@example.com", stelleId = 1))
        val b = svc.einreichen(BewerbungInput(
            vorname = "Max", nachname = "M",
            email = "max@example.com", stelleId = 2))
        assertEquals(a.bewerberId, b.bewerberId)
    }

    @Test
    fun `fehlende Pflichtfelder werfen ValidationException`() {
        val svc = BewerbungService(FakeRepo())
        val ex = assertThrows(ValidationException::class.java) {
            svc.einreichen(BewerbungInput(email = "kaputt", stelleId = 0))
        }
        assertTrue(ex.errors.size >= 3, "erwarte mindestens 3 Fehler: ${ex.errors}")
    }

    @Test
    fun `generateVorgangsNr Format`() {
        assertTrue(Regex("^BEW-\\d{4}-[0-9A-F]{6}$")
            .matches(BewerbungService.generateVorgangsNr()))
    }
}
