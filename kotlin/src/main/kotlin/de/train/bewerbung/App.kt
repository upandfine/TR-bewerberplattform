package de.train.bewerbung

import com.fasterxml.jackson.databind.PropertyNamingStrategies
import com.fasterxml.jackson.databind.SerializationFeature
import io.ktor.http.ContentType
import io.ktor.http.HttpStatusCode
import io.ktor.serialization.jackson.jackson
import io.ktor.server.application.Application
import io.ktor.server.application.call
import io.ktor.server.application.install
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.plugins.statuspages.StatusPages
import io.ktor.server.request.receive
import io.ktor.server.response.respond
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.post
import io.ktor.server.routing.routing
import java.sql.Connection
import java.sql.DriverManager
import java.sql.SQLException

/**
 * HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
 *
 *  GET  /                  -> kleiner Health-Check
 *  POST /api/bewerbungen   -> Bewerbung einreichen
 *  GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)
 */
fun main() {
    embeddedServer(Netty, host = "0.0.0.0", port = 8080) {
        module()
    }.start(wait = true)
}

fun Application.module() {
    install(ContentNegotiation) {
        jackson {
            propertyNamingStrategy = PropertyNamingStrategies.SNAKE_CASE
            disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS)
        }
    }

    install(StatusPages) {
        exception<ValidationException> { call, cause ->
            call.respond(HttpStatusCode.BadRequest,
                mapOf("fehler" to cause.message, "details" to cause.errors))
        }
        exception<SQLException> { call, cause ->
            when (cause.errorCode) {
                1452 -> call.respond(HttpStatusCode(422, "Unprocessable Entity"),
                    mapOf("fehler" to "Angegebene stelle_id existiert nicht."))
                1062 -> call.respond(HttpStatusCode.Conflict,
                    mapOf("fehler" to "Vorgangsnummer-Kollision, bitte erneut senden."))
                else -> call.respond(HttpStatusCode.InternalServerError,
                    mapOf("fehler" to "Datenbankfehler."))
            }
        }
    }

    routing {
        get("/") {
            call.respondText(
                "<h1>Kotlin / Ktor laeuft</h1><p>API unter /api/bewerbungen</p>",
                ContentType.Text.Html
            )
        }

        post("/api/bewerbungen") {
            val input = try {
                call.receive<BewerbungInput>()
            } catch (_: Exception) {
                call.respond(HttpStatusCode.BadRequest,
                    mapOf("fehler" to "Body muss gueltiges JSON sein."))
                return@post
            }
            withConnection { conn ->
                val svc = BewerbungService(JdbcBewerbungRepository(conn))
                val r = svc.einreichen(input)
                call.respond(HttpStatusCode.Created, mapOf(
                    "bewerbung_id" to r.bewerbungId,
                    "bewerber_id" to r.bewerberId,
                    "vorgangs_nr" to r.vorgangsNr,
                ))
            }
        }

        get("/api/bewerbungen") {
            val status = call.request.queryParameters["status"]
            withConnection { conn ->
                val svc = BewerbungService(JdbcBewerbungRepository(conn))
                call.respond(HttpStatusCode.OK, mapOf("bewerbungen" to svc.liste(status)))
            }
        }
    }
}

private suspend inline fun withConnection(block: (Connection) -> Unit) {
    val conn = openConnection()
    try {
        block(conn)
    } finally {
        conn.close()
    }
}

fun openConnection(): Connection {
    val host = System.getenv("DB_HOST")
    val name = System.getenv("DB_NAME")
    val user = System.getenv("DB_USER")
    val pass = System.getenv("DB_PASS")
    return DriverManager.getConnection(
        "jdbc:mariadb://$host:3306/$name?useUnicode=true&characterEncoding=utf8",
        user, pass
    )
}
