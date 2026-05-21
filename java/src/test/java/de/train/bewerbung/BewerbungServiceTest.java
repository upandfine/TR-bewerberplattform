package de.train.bewerbung;

import org.junit.jupiter.api.Test;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * UNIT-Test: prueft reine Fachlogik OHNE Datenbank.
 * Das Repository wird durch ein In-Memory-Fake ersetzt.
 */
class BewerbungServiceTest {

    private static class FakeRepo implements BewerbungRepository {
        final Map<String, Integer> emails = new HashMap<>();
        int nextId = 1;

        @Override
        public Integer findBewerberIdByEmail(String email) {
            return emails.get(email);
        }

        @Override
        public int insertBewerber(BewerberInput b) {
            int id = nextId++;
            emails.put(b.email(), id);
            return id;
        }

        @Override
        public int insertBewerbung(int bewerberId, int stelleId, String vorgangsNr, String bemerkung) {
            return nextId++;
        }

        @Override
        public List<Map<String, Object>> listBewerbungen(String status) {
            return List.of();
        }
    }

    @Test
    void einreichenLiefertVorgangsnummerImFormat() throws SQLException {
        var svc = new BewerbungService(new FakeRepo());
        var r = svc.einreichen(new BewerbungInput(
                "Erika", "Mustermann", "erika@example.com", null, 1, null));
        assertTrue(r.vorgangsNr().matches("^BEW-\\d{4}-[0-9A-F]{6}$"),
                "vorgangs_nr passt nicht: " + r.vorgangsNr());
        assertTrue(r.bewerbungId() > 0);
    }

    @Test
    void bekannteEmailWirdWiederverwendet() throws SQLException {
        var svc = new BewerbungService(new FakeRepo());
        var a = svc.einreichen(new BewerbungInput(
                "Max", "M", "max@example.com", null, 1, null));
        var b = svc.einreichen(new BewerbungInput(
                "Max", "M", "max@example.com", null, 2, null));
        assertEquals(a.bewerberId(), b.bewerberId());
    }

    @Test
    void fehlendePflichtfelderWerfenValidationException() {
        var svc = new BewerbungService(new FakeRepo());
        var ex = assertThrows(ValidationException.class,
                () -> svc.einreichen(new BewerbungInput(
                        null, null, "kaputt", null, 0, null)));
        assertTrue(ex.getErrors().size() >= 3,
                "erwarte mindestens 3 Fehler, war: " + ex.getErrors());
    }

    @Test
    void generateVorgangsNrFormat() {
        assertTrue(BewerbungService.generateVorgangsNr()
                .matches("^BEW-\\d{4}-[0-9A-F]{6}$"));
    }
}
