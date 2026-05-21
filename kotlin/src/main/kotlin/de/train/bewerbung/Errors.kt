package de.train.bewerbung

/**
 * Fachlicher Validierungsfehler -> wird im HTTP-Handler zu 400.
 * Traegt eine Liste der konkreten Feld-Fehler.
 */
class ValidationException(val errors: List<String>)
    : RuntimeException("Validierung fehlgeschlagen")
