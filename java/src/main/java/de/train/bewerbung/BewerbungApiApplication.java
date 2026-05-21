package de.train.bewerbung;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.function.Supplier;

@SpringBootApplication
public class BewerbungApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(BewerbungApiApplication.class, args);
    }

    // JSON: snake_case rein und raus (gleicher Vertrag wie PHP/Python/Node/.NET)
    @Bean
    public Jackson2ObjectMapperBuilder jacksonBuilder() {
        return new Jackson2ObjectMapperBuilder()
                .propertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
    }

    // Liefert eine MariaDB-Verbindung pro Request anhand der Umgebungs-
    // variablen DB_HOST/DB_NAME/DB_USER/DB_PASS (kommen aus der .env).
    @Bean
    public Supplier<Connection> connectionSupplier() {
        return () -> {
            String host = System.getenv("DB_HOST");
            String name = System.getenv("DB_NAME");
            String user = System.getenv("DB_USER");
            String pass = System.getenv("DB_PASS");
            String url = "jdbc:mariadb://" + host + ":3306/" + name
                    + "?useUnicode=true&characterEncoding=utf8";
            try {
                return DriverManager.getConnection(url, user, pass);
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        };
    }
}
