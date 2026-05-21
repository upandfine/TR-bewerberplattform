package de.train.bewerbung

/**
 * Eingabe-DTO der POST-API. Jackson-Mapping nutzt
 * PropertyNamingStrategy.SNAKE_CASE -> {@code stelle_id} im JSON
 * landet automatisch in {@code stelleId} hier.
 */
data class BewerbungInput(
    val vorname: String? = null,
    val nachname: String? = null,
    val email: String? = null,
    val telefon: String? = null,
    val stelleId: Int? = null,
    val bemerkung: String? = null,
)

data class BewerberInput(
    val vorname: String,
    val nachname: String,
    val email: String,
    val telefon: String?,
)

data class EinreichenResult(
    val bewerbungId: Int,
    val bewerberId: Int,
    val vorgangsNr: String,
)
