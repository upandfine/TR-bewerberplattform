package de.train.bewerbung;

import java.util.List;

/**
 * Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.
 * Traegt eine Liste der konkreten Feld-Fehler.
 */
public class ValidationException extends RuntimeException {
    private final List<String> errors;

    public ValidationException(List<String> errors) {
        super("Validierung fehlgeschlagen");
        this.errors = errors;
    }

    public List<String> getErrors() {
        return errors;
    }
}
