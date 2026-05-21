package de.train.bewerbung;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * API-/E2E-Test: echter HTTP-Durchstich durch alle Schichten
 * (Spring Boot -> Service -> Repository -> MariaDB), im Container
 * gegen http://localhost:8080.
 */
class BewerbungApiTest {

    private static final String BASE = "http://localhost:8080/api/bewerbungen";
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private String email;

    private static Connection connect() throws SQLException {
        String host = System.getenv("DB_HOST");
        String name = System.getenv("DB_NAME");
        String user = System.getenv("DB_USER");
        String pass = System.getenv("DB_PASS");
        return DriverManager.getConnection(
                "jdbc:mariadb://" + host + ":3306/" + name,
                user, pass);
    }

    @BeforeEach
    void setUp() {
        email = "javaapi+" + UUID.randomUUID().toString().replace("-", "") + "@example.com";
    }

    @AfterEach
    void tearDown() throws SQLException {
        // ON DELETE RESTRICT -> erst Bewerbung, dann Bewerber loeschen.
        try (Connection c = connect()) {
            try (PreparedStatement ps = c.prepareStatement(
                    "DELETE FROM bewerbung WHERE bewerberId IN "
                            + "(SELECT id FROM bewerber WHERE email = ?)")) {
                ps.setString(1, email);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = c.prepareStatement(
                    "DELETE FROM bewerber WHERE email = ?")) {
                ps.setString(1, email);
                ps.executeUpdate();
            }
        }
    }

    private int stelleId() throws SQLException {
        try (Connection c = connect();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT MIN(id) FROM stellenangebot")) {
            rs.next();
            int id = rs.getInt(1);
            assertTrue(id > 0, "Keine Stelle vorhanden - DB neu initialisieren.");
            return id;
        }
    }

    private HttpResponse<String> request(String method, Map<String, Object> body) throws Exception {
        HttpRequest.BodyPublisher pub = body == null
                ? HttpRequest.BodyPublishers.noBody()
                : HttpRequest.BodyPublishers.ofString(MAPPER.writeValueAsString(body));
        HttpRequest req = HttpRequest.newBuilder(URI.create(BASE))
                .header("Content-Type", "application/json")
                .method(method, pub)
                .build();
        return HttpClient.newHttpClient().send(req, HttpResponse.BodyHandlers.ofString());
    }

    @Test
    void postLegtAnUndGetListet() throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("vorname", "API");
        body.put("nachname", "Tester");
        body.put("email", email);
        body.put("stelle_id", stelleId());

        HttpResponse<String> post = request("POST", body);
        assertEquals(201, post.statusCode(), "Body: " + post.body());

        JsonNode postJson = MAPPER.readTree(post.body());
        String nummer = postJson.get("vorgangs_nr").asText();
        assertNotNull(nummer);

        HttpResponse<String> get = request("GET", null);
        assertEquals(200, get.statusCode());

        JsonNode list = MAPPER.readTree(get.body()).get("bewerbungen");
        boolean found = false;
        for (JsonNode row : list) {
            if (nummer.equals(row.get("vorgangs_nr").asText())) {
                found = true;
                break;
            }
        }
        assertTrue(found, "vorgangs_nr nicht in Liste gefunden: " + nummer);
    }

    @Test
    void postMitUngueltigenDaten400() throws Exception {
        Map<String, Object> body = new HashMap<>();
        body.put("email", "kaputt");
        body.put("stelle_id", 0);

        HttpResponse<String> res = request("POST", body);
        assertEquals(400, res.statusCode());
        JsonNode json = MAPPER.readTree(res.body());
        assertTrue(json.has("details"));
    }
}
