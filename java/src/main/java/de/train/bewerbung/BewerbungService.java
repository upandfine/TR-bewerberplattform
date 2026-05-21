package de.train.bewerbung;

import java.security.SecureRandom;
import java.sql.SQLException;
import java.time.Year;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
 * Genau deshalb ohne Datenbank unit-testbar (Fake-Repository).
 */
public final class BewerbungService {

    private static final SecureRandom RNG = new SecureRandom();

    private final BewerbungRepository repo;

    public BewerbungService(BewerbungRepository repo) {
        this.repo = repo;
    }

    public EinreichenResult einreichen(BewerbungInput input) throws SQLException {
        validate(input);

        String email = input.email().trim();

        Integer bewerberId = repo.findBewerberIdByEmail(email);
        if (bewerberId == null) {
            bewerberId = repo.insertBewerber(new BewerberInput(
                    input.vorname().trim(),
                    input.nachname().trim(),
                    email,
                    input.telefon() == null || input.telefon().isBlank()
                            ? null : input.telefon().trim()
            ));
        }

        String vorgangsNr = generateVorgangsNr();
        int bewerbungId = repo.insertBewerbung(
                bewerberId,
                input.stelleId(),
                vorgangsNr,
                input.bemerkung() == null || input.bemerkung().isBlank()
                        ? null : input.bemerkung().trim()
        );

        return new EinreichenResult(bewerbungId, bewerberId, vorgangsNr);
    }

    public List<Map<String, Object>> liste(String status) throws SQLException {
        return repo.listBewerbungen(status);
    }

    public static String generateVorgangsNr() {
        int n = RNG.nextInt(0x1000000);
        return String.format("BEW-%d-%06X", Year.now().getValue(), n);
    }

    private static void validate(BewerbungInput i) {
        List<String> errors = new ArrayList<>();

        if (i == null || i.vorname() == null || i.vorname().trim().isEmpty()) {
            errors.add("Feld 'vorname' ist ein Pflichtfeld.");
        }
        if (i == null || i.nachname() == null || i.nachname().trim().isEmpty()) {
            errors.add("Feld 'nachname' ist ein Pflichtfeld.");
        }

        String email = i == null || i.email() == null ? "" : i.email().trim();
        int at = email.indexOf('@');
        if (at < 1 || !email.substring(at + 1).contains(".")) {
            errors.add("Feld 'email' ist keine gueltige E-Mail-Adresse.");
        }

        Integer stelle = i == null ? null : i.stelleId();
        if (stelle == null || stelle <= 0) {
            errors.add("Feld 'stelle_id' muss eine positive Zahl sein.");
        }

        if (!errors.isEmpty()) {
            throw new ValidationException(errors);
        }
    }
}
