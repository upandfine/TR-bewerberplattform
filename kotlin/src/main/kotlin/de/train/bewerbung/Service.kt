package de.train.bewerbung

import java.security.SecureRandom
import java.time.Year

/**
 * Use-Case-Schicht: reine Fachlogik, kennt weder DB noch HTTP.
 * Genau deshalb ohne Datenbank unit-testbar (Fake-Repository).
 */
class BewerbungService(private val repo: BewerbungRepository) {

    fun einreichen(input: BewerbungInput): EinreichenResult {
        validate(input)

        val email = input.email!!.trim()

        val bewerberId = repo.findBewerberIdByEmail(email)
            ?: repo.insertBewerber(BewerberInput(
                vorname = input.vorname!!.trim(),
                nachname = input.nachname!!.trim(),
                email = email,
                telefon = input.telefon?.trim()?.takeIf { it.isNotEmpty() },
            ))

        val vorgangsNr = generateVorgangsNr()
        val bewerbungId = repo.insertBewerbung(
            bewerberId,
            input.stelleId!!,
            vorgangsNr,
            input.bemerkung?.trim()?.takeIf { it.isNotEmpty() },
        )

        return EinreichenResult(bewerbungId, bewerberId, vorgangsNr)
    }

    fun liste(status: String?): List<Map<String, Any?>> = repo.listBewerbungen(status)

    companion object {
        private val RNG = SecureRandom()

        fun generateVorgangsNr(): String {
            val n = RNG.nextInt(0x1000000)
            return "BEW-${Year.now().value}-%06X".format(n)
        }

        private fun validate(i: BewerbungInput) {
            val errors = mutableListOf<String>()

            if (i.vorname.isNullOrBlank()) errors += "Feld 'vorname' ist ein Pflichtfeld."
            if (i.nachname.isNullOrBlank()) errors += "Feld 'nachname' ist ein Pflichtfeld."

            val email = i.email?.trim().orEmpty()
            val at = email.indexOf('@')
            if (at < 1 || !email.substring(at + 1).contains('.')) {
                errors += "Feld 'email' ist keine gueltige E-Mail-Adresse."
            }

            val stelle = i.stelleId
            if (stelle == null || stelle <= 0) {
                errors += "Feld 'stelle_id' muss eine positive Zahl sein."
            }

            if (errors.isNotEmpty()) throw ValidationException(errors)
        }
    }
}
