package de.train.bewerbung;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Naht zwischen Service (reine Logik) und Persistenz.
 * Im Unit-Test wird diese Schnittstelle durch ein In-Memory-Fake
 * ersetzt -> Service-Tests brauchen keine Datenbank.
 */
public interface BewerbungRepository {

    Integer findBewerberIdByEmail(String email) throws SQLException;

    int insertBewerber(BewerberInput bewerber) throws SQLException;

    int insertBewerbung(int bewerberId, int stelleId, String vorgangsNr, String bemerkung)
            throws SQLException;

    List<Map<String, Object>> listBewerbungen(String status) throws SQLException;
}
