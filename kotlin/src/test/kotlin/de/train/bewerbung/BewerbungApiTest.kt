package de.train.bewerbung

import com.fasterxml.jackson.databind.ObjectMapper
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.util.UUID

/**
 * API-/E2E-Test: HTTP-Durchstich gegen den im Container laufenden
 * Ktor-Server (http://localhost:8080).
 */
class BewerbungApiTest {

    private val base = "http://localhost:8080/api/bewerbungen"
    private val mapper = ObjectMapper()
    private lateinit var email: String

    @BeforeEach
    fun setUp() {
        email = "ktapi+${UUID.randomUUID().toString().replace("-", "")}@example.com"
    }

    @AfterEach
    fun tearDown() {
        openConnection().use { c ->
            // ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber loeschen.
            c.prepareStatement(
                "DELETE FROM bewerbung WHERE bewerberId IN " +
                        "(SELECT id FROM bewerber WHERE email = ?)"
            ).use { ps -> ps.setString(1, email); ps.executeUpdate() }
            c.prepareStatement("DELETE FROM bewerber WHERE email = ?").use { ps ->
                ps.setString(1, email); ps.executeUpdate()
            }
        }
    }

    private fun stelleId(): Int {
        openConnection().use { c ->
            c.createStatement().use { st ->
                st.executeQuery("SELECT MIN(id) FROM stellenangebot").use { rs ->
                    rs.next()
                    val id = rs.getInt(1)
                    assertTrue(id > 0, "Keine Stelle vorhanden - DB neu initialisieren.")
                    return id
                }
            }
        }
    }

    private fun request(method: String, body: Map<String, Any?>? = null): HttpResponse<String> {
        val pub = if (body == null) HttpRequest.BodyPublishers.noBody()
        else HttpRequest.BodyPublishers.ofString(mapper.writeValueAsString(body))
        val req = HttpRequest.newBuilder(URI.create(base))
            .header("Content-Type", "application/json")
            .method(method, pub)
            .build()
        return HttpClient.newHttpClient().send(req, HttpResponse.BodyHandlers.ofString())
    }

    @Test
    fun `POST legt an und GET listet`() {
        val post = request("POST", mapOf(
            "vorname" to "API", "nachname" to "Tester",
            "email" to email, "stelle_id" to stelleId()
        ))
        assertEquals(201, post.statusCode(), "Body: ${post.body()}")

        val nummer = mapper.readTree(post.body()).get("vorgangs_nr").asText()
        assertTrue(nummer.isNotEmpty())

        val get = request("GET")
        assertEquals(200, get.statusCode())
        val nummern = mapper.readTree(get.body()).get("bewerbungen")
            .map { it.get("vorgangs_nr").asText() }
        assertTrue(nummer in nummern)
    }

    @Test
    fun `POST mit ungueltigen Daten 400`() {
        val res = request("POST", mapOf("email" to "kaputt", "stelle_id" to 0))
        assertEquals(400, res.statusCode())
        assertTrue(mapper.readTree(res.body()).has("details"))
    }
}
