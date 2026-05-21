package de.train.bewerbung;

/**
 * Eingabe-DTO der POST-API. Snake_case via Jackson-Konfiguration
 * (PropertyNamingStrategies.SNAKE_CASE) -> Felder {@code stelle_id}
 * und {@code bemerkung} werden ohne Annotation gemappt.
 */
public record BewerbungInput(
        String vorname,
        String nachname,
        String email,
        String telefon,
        Integer stelleId,
        String bemerkung
) {}
