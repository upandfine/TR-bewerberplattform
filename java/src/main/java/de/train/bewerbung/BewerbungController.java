package de.train.bewerbung;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * HTTP-Schicht: nur Request/Response-Mapping, keine Fachlogik.
 *
 *  GET  /                  -> kleiner Health-Check
 *  POST /api/bewerbungen   -> Bewerbung einreichen
 *  GET  /api/bewerbungen   -> Bewerbungen auflisten (?status=...)
 */
@RestController
@RequestMapping
public class BewerbungController {

    private final Supplier<Connection> connectionSupplier;

    public BewerbungController(Supplier<Connection> connectionSupplier) {
        this.connectionSupplier = connectionSupplier;
    }

    @GetMapping(value = "/", produces = MediaType.TEXT_HTML_VALUE)
    public String index() {
        return "<h1>Java / Spring Boot laeuft</h1><p>API unter /api/bewerbungen</p>";
    }

    @PostMapping(value = "/api/bewerbungen",
            consumes = MediaType.APPLICATION_JSON_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Object> einreichen(@RequestBody(required = false) BewerbungInput input) {
        if (input == null) {
            return error(HttpStatus.BAD_REQUEST, "Body muss gueltiges JSON sein.");
        }
        try (Connection conn = connectionSupplier.get()) {
            BewerbungService svc = new BewerbungService(new JdbcBewerbungRepository(conn));
            EinreichenResult r = svc.einreichen(input);
            Map<String, Object> body = new HashMap<>();
            body.put("bewerbung_id", r.bewerbungId());
            body.put("bewerber_id", r.bewerberId());
            body.put("vorgangs_nr", r.vorgangsNr());
            return ResponseEntity.status(HttpStatus.CREATED).body(body);
        } catch (ValidationException e) {
            Map<String, Object> body = new HashMap<>();
            body.put("fehler", e.getMessage());
            body.put("details", e.getErrors());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body);
        } catch (SQLException e) {
            int code = e.getErrorCode();
            if (code == 1452) {
                return error(HttpStatus.UNPROCESSABLE_ENTITY,
                        "Angegebene stelle_id existiert nicht.");
            }
            if (code == 1062) {
                return error(HttpStatus.CONFLICT,
                        "Vorgangsnummer-Kollision, bitte erneut senden.");
            }
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "Datenbankfehler.");
        }
    }

    @GetMapping(value = "/api/bewerbungen", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Object> liste(@RequestParam(required = false) String status) {
        try (Connection conn = connectionSupplier.get()) {
            BewerbungService svc = new BewerbungService(new JdbcBewerbungRepository(conn));
            List<Map<String, Object>> rows = svc.liste(status);
            return ResponseEntity.ok(Map.of("bewerbungen", rows));
        } catch (SQLException e) {
            return error(HttpStatus.INTERNAL_SERVER_ERROR, "Datenbankfehler.");
        }
    }

    private static ResponseEntity<Object> error(HttpStatus status, String msg) {
        return ResponseEntity.status(status).body(Map.of("fehler", msg));
    }
}
